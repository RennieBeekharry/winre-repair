// RescueMeAI minimal JSON field reader for WinRE cscript.exe
(function () {
  var a = WScript.Arguments;
  if (a.length < 2) WScript.Quit(64);
  var path = String(a(0));
  var key = String(a(1));
  var fso = new ActiveXObject("Scripting.FileSystemObject");
  if (!fso.FileExists(path)) WScript.Quit(1);
  var f = fso.OpenTextFile(path, 1, false);
  var text = f.ReadAll();
  f.Close();
  var obj;
  try { obj = eval("(" + text + ")"); } catch (e) { WScript.Quit(2); }
  if (typeof obj[key] === "undefined" || obj[key] === null) WScript.Quit(3);
  WScript.StdOut.Write(String(obj[key]));
  WScript.Quit(0);
})();
