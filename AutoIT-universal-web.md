1. Open AU3 file in script editor tool like visual studio code
2. Find string - AutoIT-universal and replace it with website name for example: PVWA
3. look for CHANGE_ME comments in script, and edit those according to your needs, everything is explained in comments
4. Compile exe from AU3 file using aut2exe - you can find exact instructions also in comments at the top of the script
cd "C:\Program Files (x86)\AutoIt3\Aut2Exe"
.\Aut2Exe.exe /in "C:\Program Files (x86)\CyberArk\PSM\Components\AutoIT-universal-web_PSM.au3" /out "C:\Program Files (x86)\CyberArk\PSM\Components\AutoIT-universal-web_PSM.exe" /x86
5. Copy .exe to Components folder on your PSM servers
6. add that exe file to applocker
<Application Name="AutoIT-universal-web_PSM" Type="Exe" Path="C:\Program Files (x86)\CyberArk\PSM\Components\AutoIT-universal-web_PSM.exe" Method="Hash" />
7. Run applocker script
8. Open and edit XML file for connection component using same find and replace method as outlined in step 2, optionally edit connection component properties in XML if needed.
Find string - AutoIT-universal and replace it with website name for example: PVWA
9. Compress that XML file into zip, its important that name of the zip begins with CC-*.zip
10. Import connection component using pspas powershell module - Import-PASConnectionComponent yourfile.zip
11. Assign this connection component to platform and test it out. It should work



MIT License

Copyright (c) 2024 Michal Masek - masek@fortwana.sk

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.