/* Command highlighter — paints known pentest tools + coreutils in code blocks the
   same "command orange" as $variables, so the tool you're running is easy to spot.
   Runs AFTER highlight.js. It only rewrites plain (untagged) text, so it never
   recolours words inside strings/comments, and matches whole tokens only — '.' and
   '-' are part of a token, so nmap.txt / web-sweep.txt / 1.2.3.4 are left alone.

   To add a command: drop its name (lowercase) into CMD_WORDS below. That's it —
   all three pages load this one file. Names with an extension (.py/.exe/.ps1) must
   be listed with the extension, since that whole thing is one token. */
(function () {
  const CMD_WORDS = new Set([
    // recon / web
    'nmap', 'masscan', 'rustscan', 'autorecon', 'ffuf', 'gobuster', 'feroxbuster', 'dirb',
    'dirbuster', 'wfuzz', 'whatweb', 'nikto', 'wpscan', 'sqlmap', 'gau', 'httpx', 'nuclei',
    'curl', 'wget',
    // AD / SMB / enumeration
    'crackmapexec', 'nxc', 'netexec', 'smbclient', 'smbmap', 'rpcclient', 'enum4linux',
    'enum4linux-ng', 'ldapsearch', 'windapsearch', 'kerbrute', 'responder', 'mitm6',
    'evil-winrm', 'bloodhound-python', 'certipy', 'certipy-ad', 'getuserspns', 'getnpusers',
    'secretsdump', 'snmpwalk', 'onesixtyone',
    // impacket (kali-packaged, .py, and bare forms)
    'impacket-secretsdump', 'impacket-getuserspns', 'impacket-getnpusers', 'impacket-psexec',
    'impacket-wmiexec', 'impacket-smbexec', 'impacket-atexec', 'impacket-mssqlclient',
    'impacket-ntlmrelayx', 'impacket-smbserver', 'impacket-ticketconverter', 'impacket-lookupsid',
    'impacket-getst', 'impacket-gettgt', 'impacket-addcomputer', 'impacket-rbcd', 'impacket-dcomexec',
    'secretsdump.py', 'getuserspns.py', 'getnpusers.py', 'psexec.py', 'wmiexec.py', 'smbexec.py',
    'mssqlclient.py', 'ntlmrelayx.py', 'smbserver.py', 'ticketer.py', 'getst.py', 'gettgt.py',
    // cracking / exploitation
    'hashcat', 'john', 'hydra', 'medusa', 'patator', 'gpp-decrypt', 'searchsploit', 'msfvenom',
    'msfconsole',
    // pivot / transfer / remote
    'socat', 'proxychains', 'proxychains4', 'chisel', 'ligolo', 'ligolo-ng', 'ssh', 'sshpass',
    'scp', 'xfreerdp', 'rdesktop', 'nc', 'ncat', 'netcat', 'rlwrap', 'nslookup', 'dig', 'tcpdump',
    'certutil', 'bitsadmin',
    // compile / lang / vcs
    'x86_64-w64-mingw32-gcc', 'i686-w64-mingw32-gcc', 'gcc', 'python3', 'python', 'php', 'ruby',
    'perl', 'git',
    // db / services
    'mysql', 'psql', 'redis-cli', 'ftp', 'tftp', 'telnet', 'showmount', 'rpcinfo', 'openssl',
    // windows tools (usually in powershell / cmd blocks)
    'rubeus.exe', 'mimikatz.exe', 'winpeasx64.exe', 'winpeasany.exe', 'sharphound.exe',
    'seatbelt.exe', 'powerview.ps1', 'powerup.ps1', 'printspoofer.exe', 'godpotato.exe',
    'juicypotato.exe', 'accesschk.exe',
    // coreutils worth spotting (distinctive names only)
    'grep', 'egrep', 'awk', 'sed', 'cut', 'sort', 'uniq', 'cat', 'head', 'tail', 'xargs', 'tee',
    'wc', 'tr', 'base64', 'xxd', 'strings', 'find', 'tar', 'unzip', 'chmod', 'chown'
  ]);

  const TOK = /[A-Za-z0-9][A-Za-z0-9._-]*/g;

  // True if this text node sits inside an existing highlight.js token span
  // (string/comment/variable/...) or a {{VAR}} placeholder — leave those alone.
  function insideToken(node, root) {
    let p = node.parentNode;
    while (p && p !== root) {
      const c = p.className || '';
      if (/(^|\s)(hljs-|unfilled)/.test(c)) return true;
      p = p.parentNode;
    }
    return false;
  }

  window.tagCommands = function (container) {
    if (!container) return;
    container.querySelectorAll('code.hljs').forEach(code => {
      const texts = [];
      const walk = document.createTreeWalker(code, NodeFilter.SHOW_TEXT, null);
      let n;
      while (n = walk.nextNode()) {
        if (!insideToken(n, code) && /[A-Za-z]/.test(n.nodeValue)) texts.push(n);
      }
      texts.forEach(textNode => {
        const text = textNode.nodeValue;
        let last = 0, m, frag = null;
        TOK.lastIndex = 0;
        while (m = TOK.exec(text)) {
          if (!CMD_WORDS.has(m[0].toLowerCase())) continue;
          if (!frag) frag = document.createDocumentFragment();
          if (m.index > last) frag.appendChild(document.createTextNode(text.slice(last, m.index)));
          const span = document.createElement('span');
          span.className = 'hljs-cmd';
          span.textContent = m[0];
          frag.appendChild(span);
          last = m.index + m[0].length;
        }
        if (frag) {
          if (last < text.length) frag.appendChild(document.createTextNode(text.slice(last)));
          textNode.parentNode.replaceChild(frag, textNode);
        }
      });
    });
  };
})();
