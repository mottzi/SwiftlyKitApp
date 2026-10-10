#!/usr/bin/env python3
"""Exercise release gates with real signatures and metadata fixtures."""

import json
from pathlib import Path
import plistlib
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
POLICY = ROOT / "script/release_validation.py"
VERIFY = ROOT / "script/verify_distribution_entitlements.sh"


class ReleaseValidationTests(unittest.TestCase):
    def test_bootstrap_release_requires_new_version_and_build(self):
        with tempfile.TemporaryDirectory() as directory:
            latest = Path(directory) / "latest.json"
            latest.write_text(json.dumps({"tagName": "0.1.1"}))
            cases = [("0.2.0", "3", True), ("0.2.0", "2", False),
                     ("0.2.0", "1", False), ("0.2.0", "0", False),
                     ("0.2.0", "03", False), ("0.1.1", "3", False),
                     ("0.1.0", "4", False), ("0.2.0-beta", "3", False)]
            for version, build, accepted in cases:
                with self.subTest(version=version, build=build):
                    result = subprocess.run(["python3", str(POLICY), "version", str(latest), version, build], capture_output=True)
                    self.assertEqual(result.returncode == 0, accepted, result.stderr)

    def test_signed_entitlements(self):
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            source = directory / "main.c"
            source.write_text("int main(void) { return 0; }\n")
            unsigned = directory / "unsigned"
            subprocess.run(["xcrun", "clang", str(source), "-o", str(unsigned)], check=True, capture_output=True)
            # clang may produce an ad hoc signature. Remove it for the failure case.
            subprocess.run(["codesign", "--remove-signature", str(unsigned)], check=True, capture_output=True)
            result = subprocess.run([str(VERIFY), str(unsigned)], capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            for name, entitlements, accepted in [
                ("absent", None, True),
                ("false", {"com.apple.security.get-task-allow": False}, True),
                ("true", {"com.apple.security.get-task-allow": True}, False),
            ]:
                with self.subTest(name=name):
                    binary = directory / name
                    binary.write_bytes(unsigned.read_bytes())
                    binary.chmod(0o755)
                    command = ["codesign", "--sign", "-", str(binary)]
                    if entitlements is not None:
                        plist = directory / f"{name}.plist"
                        plist.write_bytes(plistlib.dumps(entitlements))
                        command[1:1] = ["--entitlements", str(plist)]
                    subprocess.run(command, check=True, capture_output=True)
                    result = subprocess.run([str(VERIFY), str(binary)], capture_output=True)
                    self.assertEqual(result.returncode == 0, accepted, result.stderr)

    def test_malformed_entitlements_fail_closed(self):
        for data in [b"not a plist", plistlib.dumps({"com.apple.security.get-task-allow": "false"})]:
            with self.subTest(data=data):
                result = subprocess.run(["python3", str(POLICY), "entitlements"], input=data, capture_output=True)
                self.assertNotEqual(result.returncode, 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
