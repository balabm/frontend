# AWS Console Step-by-Step Visual Guide

This guide shows exactly what to click in the AWS Console.

---

## Step 1: Create IAM Role

### Navigate to IAM
```
AWS Console Home
  → Search bar: Type "IAM"
  → Click "IAM" (Identity and Access Management)
```

### Create Role
```
Left sidebar: Click "Roles"
  → Button: "Create role" (orange button)
```

### Select Trusted Entity
```
Trusted entity type: Select "AWS service" (should be selected by default)
Use case: Select "Lambda"
  → Click "Next" (bottom right)
```

### Add Permissions
```
Search box: Type "AmazonEC2ReadOnlyAccess"
  → ☑ Check the box next to "AmazonEC2ReadOnlyAccess"

Search box: Type "AWSLambdaBasicExecutionRole"
  → ☑ Check the box next to "AWSLambdaBasicExecutionRole"

  → Click "Next" (bottom right)
```

### Name and Create
```
Role name: LambdaEC2IpFetcherRole
Description: (optional) Role for Lambda to read EC2 instance details

Scroll down
  → Click "Create role" (orange button)
```

✅ **IAM Role Created!**

---

## Step 2: Create Lambda Function

### Navigate to Lambda
```
AWS Console Home
  → Search bar: Type "Lambda"
  → Click "Lambda"
```

### Create Function
```
  → Button: "Create function" (orange button, top right)
```

### Function Configuration
```
Select: ⦿ Author from scratch (should be selected)

Basic information:
  Function name: GetEC2PublicIP
  Runtime: Python 3.12 (or latest Python 3.x)
  Architecture: x86_64 (default is fine)

Expand "Change default execution role"
  → Select: ⦿ Use an existing role
  → Dropdown: Select "LambdaEC2IpFetcherRole"

  → Click "Create function" (orange button, bottom right)
```

✅ **Lambda Function Created!**

---

## Step 3: Add Lambda Code

### Code Editor
```
You should now see the Lambda function page

Scroll to "Code source" section
  → Click on "lambda_function.py" in the file tree (left side)
```

### Replace Code
```
1. Select all existing code (Ctrl+A)
2. Delete it
3. Open your local file: ass/lambda_function.py
4. Copy all the content (Ctrl+A, Ctrl+C)
5. Paste into Lambda editor (Ctrl+V)

  → Click "Deploy" (orange button above the code editor)
  → Wait for "Changes deployed" message
```

✅ **Code Deployed!**

---

## Step 4: Add Environment Variables

### Navigate to Configuration
```
Top of page:
  → Click "Configuration" tab (next to "Code")
```

### Environment Variables
```
Left sidebar:
  → Click "Environment variables"

  → Click "Edit" button (right side)
  → Click "Add environment variable"
```

### Add Environment Variable
```
Key:   EC2_INSTANCE_ID
Value: i-001c671f7e3b9cf60

  ⚠️ Do NOT add AWS_REGION (it's automatically provided by Lambda)

  → Click "Save" (orange button, bottom right)
  → Wait for "Successfully updated" message
```

✅ **Environment Variable Set!**

---

## Step 5: Create Function URL

### Still in Configuration Tab
```
Left sidebar:
  → Click "Function URL"

  → Click "Create function URL" (button on right)
```

### Configure Function URL
```
Auth type: Select "NONE"
  ⚠️ This makes it public - needed for mobile app

Configure cross-origin resource sharing (CORS): Leave unchecked

  → Click "Save" (orange button)
```

### Copy Function URL
```
You'll see:
  Function URL: https://abcd1234xyz.lambda-url.ap-south-1.on.aws/

  → Click the copy icon 📋 next to the URL
  → Save this URL somewhere safe! You'll need it!
```

✅ **Function URL Created!**

---

## Step 6: Test Lambda Function

### Navigate to Test
```
Top of page:
  → Click "Test" tab (next to "Code")
```

### Create Test Event
```
If first time:
  → Click "Create new event"

Event name: TestEvent
Event sharing settings: Private (default)
Template: (leave as "hello-world" or use default)
Event JSON: {} (empty JSON is fine)

  → Click "Save" (orange button)
```

### Run Test
```
  → Click "Test" button (orange button, top right)

Wait for execution to complete...

Scroll down to see "Execution result"
  → Expand "Details" section
  → Look for green "Succeeded" message
```

### Verify Response
```
You should see something like:

Response:
{
  "statusCode": 200,
  "headers": { ... },
  "body": "{\"ec2_public_ip\":\"15.206.206.190\",\"instance_id\":\"i-001c671f7e3b9cf60\", ...}"
}

✅ If you see your EC2 public IP - SUCCESS!
❌ If you see errors - check CloudWatch logs
```

---

## Step 7: Test in Browser

### Open Browser
```
1. Open any web browser
2. Paste your Function URL
3. Press Enter
```

### Expected Response
```
You should see JSON:

{
  "ec2_public_ip": "15.206.206.190",
  "instance_id": "i-001c671f7e3b9cf60",
  "instance_state": "running",
  "region": "ap-south-1"
}

✅ If you see this - PERFECT! Lambda is working!
```

---

## Step 8: Check CloudWatch Logs (Optional)

### If Something Goes Wrong
```
Lambda function page:
  → Click "Monitor" tab
  → Click "View CloudWatch logs"

  → Click the latest log stream
  → Look for error messages in red
```

---

## Troubleshooting Guide

### Problem: "EC2_INSTANCE_ID not configured"
```
Solution:
  Configuration tab → Environment variables → Edit
  Make sure EC2_INSTANCE_ID is set correctly
```

### Problem: "Instance not found"
```
Solution:
  1. Check instance ID is correct: i-001c671f7e3b9cf60
  2. Check region is correct: ap-south-1
  3. Verify EC2 instance exists in that region
```

### Problem: "No public IP address found"
```
Solution:
  1. Go to EC2 console
  2. Check instance is Running (not Stopped)
  3. Verify instance has Public IPv4 address
  4. If no public IP, start the instance
```

### Problem: "Access Denied" or "Not Authorized"
```
Solution:
  1. Check IAM role has AmazonEC2ReadOnlyAccess policy
  2. Go to IAM → Roles → LambdaEC2IpFetcherRole
  3. Click "Permissions" tab
  4. Verify policies are attached
```

### Problem: Function URL Returns 403 Forbidden
```
Solution:
  1. Configuration → Function URL
  2. Make sure Auth type is NONE
  3. Save and try again
```

---

## Visual Reference: AWS Console Layout

### Lambda Function Main Page
```
┌─────────────────────────────────────────────────────┐
│ Lambda > Functions > GetEC2PublicIP                 │
├─────────────────────────────────────────────────────┤
│                                                      │
│  [Code]  [Test]  [Configuration]  [Aliases]  ...   │ ← Tabs
│                                                      │
│  ┌────────────────────────────────────────────┐   │
│  │                                             │   │
│  │         Code source                         │   │
│  │                                             │   │
│  │  lambda_function.py                        │   │
│  │  ┌──────────────────────────────────────┐ │   │
│  │  │ def lambda_handler(event, context):  │ │   │
│  │  │     ...                               │ │   │
│  │  └──────────────────────────────────────┘ │   │
│  │                                             │   │
│  │  [Deploy]  [Test]                          │   │
│  │                                             │   │
│  └────────────────────────────────────────────┘   │
│                                                      │
└─────────────────────────────────────────────────────┘
```

### Configuration Tab Layout
```
┌─────────────────────────────────────────────────────┐
│  [Code]  [Test]  [Configuration]  [Aliases]  ...   │
│           ^^^^^^^^^^^^^^                            │
├─────────────────────────────────────────────────────┤
│                                                      │
│  Left Sidebar:              Right Panel:            │
│  ┌──────────────┐          ┌─────────────────────┐│
│  │ General      │          │                      ││
│  │ Permissions  │          │ Configuration        ││
│  │ Environment  │ ←        │ details here         ││
│  │   variables  │          │                      ││
│  │ Function URL │          │                      ││
│  │ ...          │          │                      ││
│  └──────────────┘          └─────────────────────┘│
│                                                      │
└─────────────────────────────────────────────────────┘
```

---

## Time Estimates

| Step | Time Required |
|------|---------------|
| Create IAM Role | 5 minutes |
| Create Lambda Function | 3 minutes |
| Add Code | 2 minutes |
| Set Environment Variables | 2 minutes |
| Create Function URL | 2 minutes |
| Test Lambda | 3 minutes |
| **Total** | **~17 minutes** |

---

## Success Checklist

After completing all steps, verify:

- [ ] IAM Role `LambdaEC2IpFetcherRole` exists
- [ ] Role has both required policies attached
- [ ] Lambda function `GetEC2PublicIP` exists
- [ ] Lambda code is deployed (no default code)
- [ ] Environment variables are set (2 variables)
- [ ] Function URL exists and is public (Auth: NONE)
- [ ] Function URL works in browser
- [ ] Response shows your EC2 public IP
- [ ] Function URL copied and saved

---

## Next Steps

After AWS setup is complete:

1. Open `lib/services/ec2_ip_service.dart`
2. Update line 5 with your Function URL
3. Save and rebuild Flutter app
4. Test the "Auto-Fetch URLs" button

---

## Screenshots Location (if needed)

If you need help, you can take screenshots of:
1. IAM Role page (showing policies)
2. Lambda function page (showing code)
3. Environment variables page
4. Function URL configuration
5. Test execution results

These help with troubleshooting if needed.

---

**Remember**: Your Lambda Function URL is permanent - save it somewhere safe!

Format: `https://[unique-id].lambda-url.[region].on.aws/`

Example: `https://xyz123abc456.lambda-url.ap-south-1.on.aws/`
