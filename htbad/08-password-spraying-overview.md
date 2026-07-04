# Section 8: Password Spraying Overview

- Module: Active Directory Enumeration & Attacks (143)
- URL: https://academy.hackthebox.com/app/module/143/section/1424
- Code/command blocks: 1

> Terminal output is omitted; only commands & scripts are captured.

```bash
#!/bin/bash

for x in {{A..Z},{0..9}}{{A..Z},{0..9}}{{A..Z},{0..9}}{{A..Z},{0..9}}
    do echo $x;
done
```

