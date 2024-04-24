# AutoIT Universal Web

## How to Use

1. Open AU3 file in a script editor tool like Visual Studio Code.
2. Find the string `AutoIT-universal` and replace it with the website name, for example: `PVWA`.
3. Look for `CHANGE_ME` comments in the script, and edit those according to your needs. Everything is explained in the comments.
4. Compile the .exe from the AU3 file using `aut2exe`. You can find exact instructions also in the comments at the top of the script:
    ```shell
    cd "C:\Program Files (x86)\AutoIt3\Aut2Exe"
    .\Aut2Exe.exe /in "C:\Program Files (x86)\CyberArk\PSM\Components\AutoIT-universal-web_PSM.au3" /out "C:\Program Files (x86)\CyberArk\PSM\Components\AutoIT-universal-web_PSM.exe" /x86
    ```
5. Copy the .exe to the Components folder on your PSM servers.
6. Add that .exe file to AppLocker:
    ```xml
    <Application Name="AutoIT-universal-web_PSM" Type="Exe" Path="C:\Program Files (x86)\CyberArk\PSM\Components\AutoIT-universal-web_PSM.exe" Method="Hash" />
    ```
7. Run the AppLocker script.
8. Open and edit the XML file for the connection component using the same find and replace method as outlined in step 2. Optionally, edit the connection component properties in the XML if needed. Find the string `AutoIT-universal` and replace it with the website name, for example: `PVWA`.
9. Compress that XML file into a .zip. It's important that the name of the .zip begins with `CC-*.zip`.
10. Import the connection component using the `pspas` PowerShell module: `Import-PASConnectionComponent yourfile.zip`.
11. Assign this connection component to the platform and test it out. It should work.

## Licensing

MIT License

Copyright (c) 2024 Michal Masek - masek@fortwana.sk

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
