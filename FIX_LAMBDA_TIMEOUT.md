# 🔥 URGENT FIX: Lambda Timeout Error

## ❌ Error You're Seeing:
```json
{
  "errorType": "Sandbox.Timedout",
  "errorMessage": "RequestId: ... Error: Task timed out after 3.00 seconds"
}
```

---

## ✅ QUICK FIX (Do This Now!)

### Fix #1: Increase Lambda Timeout (REQUIRED)

**Default timeout is 3 seconds - TOO SHORT for EC2 API calls!**

#### Steps:
```
1. Lambda Console → GetEC2PublicIP function
2. Click "Configuration" tab (top)
3. Click "General configuration" (left sidebar)
4. Click "Edit" button (right side)
5. Find "Timeout" field
6. Change from: 3 sec
   Change to:   10 sec
7. Click "Save" (orange button)
```

**This should fix it immediately!**

---

### Fix #2: Redeploy Updated Code

I've updated the Lambda code to be more efficient. Redeploy it:

```
1. Go to "Code" tab
2. Copy the UPDATED lambda_function.py from your project
3. Paste into Lambda editor (replace all code)
4. Click "Deploy" button
5. Wait for "Changes deployed" message
```

The updated code:
- ✅ Initializes EC2 client once (faster)
- ✅ Adds logging for debugging
- ✅ More efficient execution

---

### Fix #3: Check Lambda VPC Settings (If Still Timing Out)

**Is Lambda in a VPC?**

#### Check:
```
1. Configuration tab → VPC
2. If it says "No VPC" → GOOD! (no action needed)
3. If it shows a VPC → This might be the problem
```

#### If Lambda is in a VPC:
- Lambda needs **internet access** to call AWS EC2 API
- Options:
  - **Option A (Easy)**: Remove Lambda from VPC
    - Configuration → VPC → Edit → "No VPC" → Save
  - **Option B (Advanced)**: Add NAT Gateway to VPC (costs money)

**Recommendation**: Unless you have a specific reason, Lambda should NOT be in a VPC for this use case.

---

## 🧪 Test After Fix

### Step 1: Test in Lambda Console
```
1. Go to "Test" tab
2. Click "Test" button
3. Wait for result (should be < 5 seconds now)
4. Look for: "statusCode": 200
5. Should see your EC2 IP in the response
```

### Step 2: Check Logs
```
If it still fails:
1. Scroll down to "Execution result"
2. Click "Logs" section
3. Look for print statements:
   - "Fetching IP for instance: i-001c671f7e3b9cf60..."
   - "Created new EC2 client for region: ap-south-1"
   - "Calling describe_instances..."
```

### Step 3: Test in Browser
```
1. Get your Function URL
2. Paste in browser
3. Should see JSON with EC2 IP
```

---

## 📊 What Causes Timeout?

| Cause | Likelihood | Solution |
|-------|-----------|----------|
| **Timeout too short (3s)** | 🔴 Very High | ✅ Increase to 10s |
| **Lambda in VPC without NAT** | 🟡 Medium | Remove from VPC |
| **IAM permissions missing** | 🟢 Low | Check role has EC2 read access |
| **Wrong region** | 🟢 Low | Verify Lambda in ap-south-1 |
| **Code not deployed** | 🟡 Medium | Click "Deploy" button |

---

## 🎯 Expected Timing

After fixes:
- **First execution** (cold start): 2-5 seconds
- **Subsequent executions**: 0.5-2 seconds
- **Timeout setting**: 10 seconds (plenty of buffer)

---

## ✅ Verification Checklist

After applying fixes, verify:

- [ ] Timeout increased to 10 seconds
- [ ] Updated lambda_function.py code deployed
- [ ] Test execution shows "statusCode": 200
- [ ] Test execution completes in < 5 seconds
- [ ] Response includes "ec2_public_ip"
- [ ] Function URL works in browser
- [ ] No VPC or VPC has internet access

---

## 🔍 CloudWatch Logs (Advanced Debugging)

If still having issues, check detailed logs:

```
1. Lambda function page → "Monitor" tab
2. Click "View CloudWatch logs"
3. Click the latest log stream
4. Look for errors in red
5. Check for:
   - Network timeouts
   - Permission errors
   - API call failures
```

Common log messages:
- ✅ `"Fetching IP for instance..."` - Good, function started
- ✅ `"Created new EC2 client..."` - Good, client initialized
- ❌ `"timed out"` - Network/VPC issue
- ❌ `"Access Denied"` - IAM permission issue

---

## 🆘 Still Not Working?

If timeout persists after all fixes:

### Option 1: Recreate Lambda Function
```
Sometimes it's faster to start fresh:
1. Delete current Lambda function
2. Create new one (following setup guide)
3. Make sure:
   - NOT in VPC
   - Timeout = 10 seconds
   - Correct IAM role
   - In ap-south-1 region
```

### Option 2: Check EC2 Instance
```
1. Go to EC2 Console
2. Verify instance i-001c671f7e3b9cf60 exists
3. Verify it's in ap-south-1 region
4. Check it's Running (not Stopped)
5. Verify it has a Public IPv4 address
```

### Option 3: Test IAM Permissions
```
Try a simpler test:
1. Lambda code → Test tab
2. Create test with this code instead:
   
   import boto3
   def lambda_handler(event, context):
       client = boto3.client('ec2', region_name='ap-south-1')
       response = client.describe_regions()
       return {'statusCode': 200, 'body': str(response)}
   
3. If this works → IAM permissions OK
4. If this fails → IAM role issue
```

---

## 💡 Pro Tips

1. **Always check timeout first** - 90% of Lambda issues are timeout-related
2. **Avoid VPCs unless necessary** - They add complexity
3. **Use CloudWatch logs** - They show exactly what's failing
4. **Test incrementally** - Fix one thing at a time

---

## 📝 Summary

**Most likely fix**: Just increase timeout from 3s → 10s

**Do this in order**:
1. ✅ Increase timeout to 10 seconds (Configuration → General configuration)
2. ✅ Redeploy updated code (click Deploy button)
3. ✅ Test again (should work now!)
4. ⏭️ If still fails, check VPC settings
5. ⏭️ If still fails, check CloudWatch logs

---

**After fixing, continue with Step 6 (Test the Lambda Function) in the main setup guide!**

Good luck! 🚀
