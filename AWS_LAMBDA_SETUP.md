# AWS Lambda Setup Guide for EC2 IP Fetching

This guide will help you set up a Lambda function to automatically fetch your EC2's public IP address.

## 📋 Overview

**Problem**: Your EC2 instance's public IP changes when you stop/start it, requiring manual URL updates in your app.

**Solution**: Create a Lambda function that fetches the current EC2 IP and returns it via a Function URL.

**Your EC2 Details**:
- Instance ID: `i-001c671f7e3b9cf60`
- Region: `ap-south-1` (Mumbai)
- Name: FormBot

---

## 🚀 Step-by-Step AWS Console Setup

### Step 1: Create IAM Role for Lambda

1. Go to **AWS Console** → **IAM** → **Roles**
2. Click **"Create role"**
3. Select:
   - **Trusted entity type**: AWS service
   - **Use case**: Lambda
4. Click **"Next"**
5. **Add permissions** - Search and attach these policies:
   - ✅ `AmazonEC2ReadOnlyAccess` (to read EC2 instance details)
   - ✅ `AWSLambdaBasicExecutionRole` (for CloudWatch logs)
6. Click **"Next"**
7. **Role name**: `LambdaEC2IpFetcherRole`
8. Click **"Create role"**

---

### Step 2: Create Lambda Function

1. Go to **AWS Console** → **Lambda** → **Functions**
2. Click **"Create function"**
3. Choose **"Author from scratch"**
4. Configure:
   - **Function name**: `GetEC2PublicIP`
   - **Runtime**: Python 3.12 (or latest Python 3.x)
   - **Architecture**: x86_64 (or arm64 if you prefer)
   - **Permissions**: 
     - Expand "Change default execution role"
     - Select "Use an existing role"
     - Choose: `LambdaEC2IpFetcherRole` (the role you just created)
5. Click **"Create function"**

---

### Step 3: Add Lambda Function Code

1. In the Lambda function page, scroll down to **"Code source"**
2. Delete the existing code in `lambda_function.py`
3. Copy and paste the code from `lambda_function.py` file (provided in your project)
4. Click **"Deploy"** (orange button at the top)

---

### Step 4: Configure Environment Variables

1. In the Lambda function page, click the **"Configuration"** tab
2. Click **"Environment variables"** on the left
3. Click **"Edit"**
4. Click **"Add environment variable"**
5. Add this variable:

   | Key | Value |
   |-----|-------|
   | `EC2_INSTANCE_ID` | `i-001c671f7e3b9cf60` |

   ⚠️ **Note**: Do NOT add `AWS_REGION` - it's automatically provided by Lambda (reserved variable)

6. Click **"Save"**

---

### Step 4.5: Increase Timeout (Important!)

⚠️ **Lambda timeout needs to be increased from default 3 seconds**

1. Still in **"Configuration"** tab
2. Click **"General configuration"** on the left
3. Click **"Edit"**
4. Change **Timeout** from `3 sec` to `10 sec`
5. Click **"Save"**

This ensures Lambda has enough time to query the EC2 API.

---

### Step 5: Create Function URL (Public Endpoint)

1. In the Lambda function page, click the **"Configuration"** tab
2. Click **"Function URL"** on the left
3. Click **"Create function URL"**
4. Configure:
   - **Auth type**: Select **"NONE"** (public access - required for your mobile app)
   - ⚠️ **Warning**: This makes the endpoint public. It's safe because it only reads EC2 info.
5. Click **"Save"**
6. **Copy the Function URL** - it will look like:
   ```
   https://abcd1234xyz.lambda-url.ap-south-1.on.aws/
   ```
   **⭐ SAVE THIS URL - YOU'LL NEED IT!**

---

### Step 6: Test the Lambda Function

1. Go back to the **"Code"** tab
2. Click **"Test"** button (top right)
3. Configure test event:
   - **Event name**: `TestEvent`
   - **Event JSON**: Leave as default `{}` or use:
     ```json
     {}
     ```
4. Click **"Save"**
5. Click **"Test"** again
6. Check the **Execution results** - you should see:
   ```json
   {
     "statusCode": 200,
     "body": "{\"ec2_public_ip\": \"15.206.206.190\", ...}"
   }
   ```

---

### Step 7: Test via Browser

1. Open your browser
2. Paste the Function URL you copied (e.g., `https://abcd1234xyz.lambda-url.ap-south-1.on.aws/`)
3. You should see JSON response:
   ```json
   {
     "ec2_public_ip": "15.206.206.190",
     "instance_id": "i-001c671f7e3b9cf60",
     "instance_state": "running",
     "region": "ap-south-1"
   }
   ```

✅ **If you see the IP, it's working!**

---

## 📱 Step 8: Update Your Flutter App

1. Open `lib/services/ec2_ip_service.dart`
2. Find this line:
   ```dart
   static const String lambdaFunctionUrl = 'YOUR_LAMBDA_FUNCTION_URL_HERE';
   ```
3. Replace with your actual Function URL:
   ```dart
   static const String lambdaFunctionUrl = 'https://YOUR_ACTUAL_URL.lambda-url.ap-south-1.on.aws/';
   ```
4. Save the file

---

## 🎯 How to Use in Your App

### Automatic URL Fetching:
1. Open the app
2. Go to **Settings** screen
3. Click **"Auto-Fetch URLs from EC2"** button
4. The app will fetch the current EC2 IP and populate all URL fields automatically

### Manual Entry (Backup):
- You can still manually enter/edit URLs if needed

### URL Format After Auto-Fetch:
The URLs will be automatically set to:
```
Bounding Box URL: http://15.206.206.190:8001/cv/form-detection-with-box/
OCR Text URL:     http://15.206.206.190:8002/cv/ocr
ASR URL:          http://15.206.206.190:8003/upload-audio-zip/
LLM URL:          http://15.206.206.190:8004/get_llm_response
```

---

## 🔄 Testing the Complete Flow

1. **Stop your EC2 instance** in AWS Console
2. **Start it again** (IP will change)
3. **Open your app**
4. Go to **Settings**
5. Click **"Auto-Fetch URLs from EC2"**
6. ✅ URLs should update with the new IP automatically!

---

## 💰 Cost Considerations

- **Lambda**: First 1 million requests/month are FREE
- Your app will make ~1-2 requests per day = ~60 requests/month
- **Cost**: $0.00 (well within free tier)

---

## 🔒 Security Notes

1. **Public Function URL**: Safe because it only reads EC2 info (no write access)
2. **IAM Role**: Has read-only EC2 permissions
3. **Best Practice**: If you want extra security, you can add API key authentication later

---

## 🐛 Troubleshooting

### Error: "Task timed out after 3.00 seconds" (Sandbox.Timedout)
This is the most common error! Solutions:
1. **Increase timeout**: Configuration → General configuration → Timeout → Change to `10 seconds`
2. **Check VPC settings**: If Lambda is in a VPC, ensure it has internet access (NAT Gateway)
3. **Redeploy code**: Click "Deploy" button after pasting the lambda_function.py code
4. **Check IAM permissions**: Verify role has `AmazonEC2ReadOnlyAccess`

### Error: "EC2_INSTANCE_ID not configured"
- Check environment variables in Lambda Configuration tab
- Ensure `EC2_INSTANCE_ID` is set to `i-001c671f7e3b9cf60`

### Error: "Instance not found"
- Verify instance ID is correct: `i-001c671f7e3b9cf60`
- Lambda automatically uses the region where it's deployed (ap-south-1)
- Make sure your Lambda is in the same region as your EC2 instance

### Error: "No public IP address found"
- Make sure EC2 instance is **running**
- Check that EC2 has "Auto-assign Public IP" enabled

### App shows "Failed to fetch EC2 IP"
- Verify Function URL is correctly set in `ec2_ip_service.dart`
- Test Function URL in browser first
- Check internet connection on mobile device

---

## ✅ Final Checklist

- [ ] IAM Role created with EC2 read permissions
- [ ] Lambda function created and deployed **in ap-south-1 region**
- [ ] Environment variable set: `EC2_INSTANCE_ID` = `i-001c671f7e3b9cf60`
- [ ] Function URL created and tested in browser
- [ ] Function URL updated in Flutter app code
- [ ] App rebuilt and tested
- [ ] Auto-fetch button works in Settings screen

**Important**: Make sure your Lambda function is created in the **ap-south-1** (Mumbai) region, same as your EC2 instance!

---

## 📞 Need Help?

If something doesn't work:
1. Check Lambda CloudWatch Logs (Monitor tab → View logs in CloudWatch)
2. Test Function URL in browser first
3. Verify EC2 is running and has public IP
4. Check Flutter app console for error messages

---

**Your Lambda Function URL** (save this):
```
https://________________________.lambda-url.ap-south-1.on.aws/
```

Fill this in after Step 5!
