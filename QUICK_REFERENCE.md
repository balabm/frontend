# Quick Reference - Lambda Function URL

## After Setup, Your URLs Will Look Like:

### Lambda Function URL (to get EC2 IP):
```
https://abcd1234xyz.lambda-url.ap-south-1.on.aws/
```

### Response Format:
```json
{
  "ec2_public_ip": "15.206.206.190",
  "instance_id": "i-001c671f7e3b9cf60",
  "instance_state": "running",
  "region": "ap-south-1"
}
```

### What the App Does:
1. App calls Lambda Function URL
2. Lambda returns current EC2 public IP
3. App automatically constructs these URLs:
   - `http://[EC2_IP]:8001/cv/form-detection-with-box/`
   - `http://[EC2_IP]:8002/cv/ocr`
   - `http://[EC2_IP]:8003/upload-audio-zip/`
   - `http://[EC2_IP]:8004/get_llm_response`
4. URLs saved in SharedPreferences

---

## Setup Steps (Quick):

1. **Create IAM Role** → `LambdaEC2IpFetcherRole` with `AmazonEC2ReadOnlyAccess`
2. **Create Lambda** → Runtime: Python 3.12, Use existing role
3. **Add Code** → Copy from `lambda_function.py`
4. **Set Environment Variables**:
   - `EC2_INSTANCE_ID` = `i-001c671f7e3b9cf60`
   - (AWS_REGION is automatic - don't add it)
5. **Create Function URL** → Auth: NONE
6. **Test** → Browser or Lambda console
7. **Update Flutter App** → `lib/services/ec2_ip_service.dart` line 5

---

## Files Modified/Created:

✅ `lib/services/ec2_ip_service.dart` - Service to fetch EC2 IP from Lambda  
✅ `lib/screens/settings_screen.dart` - Updated with auto-fetch button  
✅ `lambda_function.py` - Lambda function code (deploy this to AWS)  
✅ `AWS_LAMBDA_SETUP.md` - Complete setup guide  
✅ `QUICK_REFERENCE.md` - This file  

---

## How Users Will Use It:

### Option 1: Automatic (Recommended)
1. Open app → Settings
2. Click "Auto-Fetch URLs from EC2"
3. URLs populate automatically ✅

### Option 2: Manual (Backup)
1. Open app → Settings
2. Type URLs manually
3. Click "Save Settings" ✅

---

## Testing After EC2 Restart:

```bash
# Step 1: Restart EC2
AWS Console → EC2 → Stop → Start (IP changes from X.X.X.X to Y.Y.Y.Y)

# Step 2: Test Lambda
Browser: https://your-lambda-url/
Response: {"ec2_public_ip": "Y.Y.Y.Y", ...}

# Step 3: Test App
Open App → Settings → Auto-Fetch
URLs update to: http://Y.Y.Y.Y:8001/... ✅
```

---

## Cost: $0 (Free Tier)
- Lambda: 1M requests/month free
- Your usage: ~60 requests/month
- EC2 API calls: Free

---

## Security:
- ✅ Lambda has read-only EC2 access
- ✅ No write permissions
- ✅ No sensitive data exposed
- ✅ Public URL is safe (only returns IP)

---

## Troubleshooting:

| Error | Solution |
|-------|----------|
| "Failed to fetch EC2 IP" | Check Lambda Function URL in code |
| "No public IP found" | Ensure EC2 is running |
| "CORS error" | Check Lambda headers include CORS |
| "Timeout" | Increase Lambda timeout (default 3s → 10s) |

---

## Lambda Function URL Format:
```
https://<unique-id>.lambda-url.<region>.on.aws/
```

Example:
```
https://abcd1234xyz5678.lambda-url.ap-south-1.on.aws/
```

**This URL never changes** - even when EC2 IP changes! 🎉
