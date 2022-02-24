"""
Add a license to the doctsring of every script.
You can edit the license here and re-run the script to update it.

!! The license always had to be at the end of the docstring !!
!! Don't put anything after !!

This is a Python 3+ script.

[LICENSE]

    Copyright 2022 Liam Collod
    
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    
       http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

"""
import os
import re
from pathlib import Path
from typing import Set


# this can be updated as you wish
LICENSE_TXT = """
    Copyright 2022 Liam Collod
    
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    
       http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
"""

# do not change this else file using the previous version could not
# see their LICENSE updated properly
LICENSE_PREFIX = "\n[LICENSE]\n"


def get_files_from_root(root_dir: Path) -> Set[Path]:
    """
    Return all the code file the root directory has.
    Only process .py for now.
    """
    out = set()
    for entry in os.scandir(root_dir):
        entry = Path(entry.path)
        if entry.is_dir():
            out.update(get_files_from_root(entry))
        elif entry.suffix == ".lua":
            out.add(entry)
    return out


def code_remove_license(file: Path) -> str:
    """
    The given file MUST have an existing top docstring.
    """

    pattern = f"^--\\[\\[([\\s\\S]*?){re.escape(LICENSE_PREFIX)}[\\s\\S]*?\\]\\]"
    code = file.read_text(encoding="utf-8")
    new_code = re.sub(
        pattern=pattern,
        repl="\"\"\"\\1\"\"\"",
        string=code
    )
    print(f"[code_remove_license] Finished for <{file}>")
    return new_code


def code_insert_licence(file: Path) -> str:

    code = file.read_text(encoding="utf-8")

    pattern = re.compile("^--\\[\\[([\\s\\S]*?)\\]\\]")
    docstring = pattern.match(code)
    if not docstring:
        new_code = f"--[[{LICENSE_PREFIX}{LICENSE_TXT}]]\n"
        new_code += code
        print(
            f"[code_insert_licence] Finished for <{file}>."
            f"New docstring created."
        )
        return new_code

    if LICENSE_PREFIX in docstring.group():
        code = code_remove_license(file)

    new_code = pattern.sub(
        repl=f"--[[\\1{LICENSE_PREFIX}{LICENSE_TXT}\n]]",
        string=code
    )

    print(f"[code_insert_licence] Finished for <{file}>.")
    return new_code


def run():

    print("-"*50)

    root = Path(r"..").resolve()
    if not root.exists() or not root.is_dir():
        raise FileNotFoundError(f"[run] Root dir {root} doesnt exists or not a directory.")

    file_list = get_files_from_root(root)
    print(f"[run] Start processing {len(file_list)} files for root <{root}>")

    for file_path in file_list:
        new_content = code_insert_licence(file_path)
        # print(
        #     f"------------------------------------"
        #     f"[{file_path}] content is now:\n\n"
        #     f"{new_content}\n"
        #     f"{'X' * 150}\n\n\n"
        # )
        file_path.write_text(new_content, encoding="utf-8")
        print(f"[run] Processed <{file_path}>")
        continue

    print("[run] Finished")
    return


if __name__ == '__main__':
    run()