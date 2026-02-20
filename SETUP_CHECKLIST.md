# Setup Checklist ✅

Follow this checklist step-by-step to set up automatic EC2 IP fetching.

---

## Phase 1: AWS Lambda Setup (30 minutes)

### IAM Role Creation
- [ ] Go to AWS Console → IAM → Roles
- [ ] Create role → AWS service → Lambda
- [ ] Attach policy: `AmazonEC2ReadOnlyAccess`
- [ ] Attach policy: `AWSLambdaBasicExecutionRole`
- [ ] Role name: `LambdaEC2IpFetcherRole`
- [ ] Click Create

### Lambda Function Creation
- [ ] Go to AWS Console → Lambda → Functions
- [ ] Click Create function
- [ ] Function name: `GetEC2PublicIP`
- [ ] Runtime: Python 3.12
- [ ] Use existing role: `LambdaEC2IpFetcherRole`
- [ ] Click Create

### Lambda Code Deployment
- [ ] Open `lambda_function.py` from your project
- [ ] Copy all the code
- [ ] Paste into Lambda code editor
- [ ] Click Deploy button

### Environment Variables
- [ ] Configuration tab → Environment variables → Edit
- [ ] Add variable: `EC2_INSTANCE_ID` = `i-001c671f7e3b9cf60`
- [ ] **Do NOT add AWS_REGION** (it's automatically provided by Lambda)
- [ ] Click Save

### Function URL Setup
- [ ] Configuration tab → Function URL
- [ ] Click Create function URL
- [ ] Auth type: NONE
- [ ] Click Save
- [ ] **COPY THE URL** → Save it somewhere safe!
  ```
  Your URL: _________________________________
  ```

### Lambda Testing
- [ ] Go to Test tab
- [ ] Create test event (use default `{}`)
- [ ] Click Test
- [ ] Verify response shows `ec2_public_ip`
- [ ] Test URL in browser
- [ ] Verify JSON response appears

---

## Phase 2: Flutter App Update (10 minutes)

### Update Service File
- [ ] Open `lib/services/ec2_ip_service.dart`
- [ ] Find line 5: `static const String lambdaFunctionUrl = ...`
- [ ] Paste your Lambda Function URL
- [ ] Save file

### Test Code Changes
- [ ] Run: `flutter pub get` (if needed)
- [ ] Check for any errors
- [ ] Build app: `flutter run` or `flutter build apk`

---

## Phase 3: Testing (15 minutes)

### Initial Test (with Current IP)
- [ ] Open app on device/emulator
- [ ] Navigate to Settings screen
- [ ] Click "Auto-Fetch URLs from EC2"
- [ ] Wait for "URLs updated from EC2" message
- [ ] Verify all 4 URLs are populated
- [ ] Verify IP matches your current EC2 IP
- [ ] Check console logs for success messages

### Full Integration Test (with IP Change)
- [ ] Go to AWS Console → EC2
- [ ] Note current public IP: `________________`
- [ ] Stop the EC2 instance
- [ ] Wait for instance to stop
- [ ] Start the EC2 instance
- [ ] Note new public IP: `________________`
- [ ] Open your app
- [ ] Go to Settings
- [ ] Click "Auto-Fetch URLs from EC2"
- [ ] Verify URLs show NEW IP
- [ ] Test an actual API call (take photo, process form)
- [ ] Verify it works with new IP

### Edge Case Testing
- [ ] Test with airplane mode (should show error gracefully)
- [ ] Test with EC2 stopped (should show appropriate error)
- [ ] Test manual URL entry (should still work)
- [ ] Test saving manual URLs (should override auto-fetch)

---

## Phase 4: Documentation (5 minutes)

### Record Information
- [ ] Lambda Function URL: `_____________________________`
- [ ] Lambda Function Name: `GetEC2PublicIP`
- [ ] IAM Role Name: `LambdaEC2IpFetcherRole`
- [ ] EC2 Instance ID: `i-001c671f7e3b9cf60`
- [ ] Region: `ap-south-1`

### Share with Team
- [ ] Document Lambda URL in team wiki/docs
- [ ] Share setup guide with team
- [ ] Add Lambda URL to password manager (if using)

---

## Troubleshooting Section

### If Lambda Test Fails
- [ ] Check environment variables are set correctly
- [ ] Verify IAM role has EC2 read permissions
- [ ] Check CloudWatch logs for errors
- [ ] Verify instance ID is correct

### If App Shows "Failed to fetch"
- [ ] Verify Lambda Function URL is correct in code
- [ ] Test Lambda URL in browser first
- [ ] Check device has internet connection
- [ ] Verify Lambda Function URL has Auth: NONE

### If URLs Don't Update
- [ ] Check SharedPreferences is saving correctly
- [ ] Verify response parsing is working (check logs)
- [ ] Try clearing app data and retest

---

## Success Criteria ✅

You're done when:
- [ ] Lambda function returns EC2 IP when called from browser
- [ ] App Settings screen has "Auto-Fetch" button
- [ ] Clicking button populates all 4 URL fields
- [ ] URLs use current EC2 public IP
- [ ] Manual URL entry still works as backup
- [ ] App works correctly after EC2 restart

---

## Maintenance

### Regular Tasks
- **Never**: Lambda URL never changes (set once, forget it)
- **Monthly**: Check Lambda is still working (optional)
- **When EC2 stops/starts**: Just click "Auto-Fetch" in app

### Cost Monitoring
- [ ] Set up AWS billing alert (optional, but recommended)
- [ ] Monitor Lambda usage (should be ~60 requests/month)
- [ ] Cost should be $0.00 (free tier)

---

## Support Files

- `AWS_LAMBDA_SETUP.md` - Detailed setup instructions
- `QUICK_REFERENCE.md` - Quick reference guide
- `ARCHITECTURE_DIAGRAM.md` - Visual flow diagrams
- `lambda_function.py` - Lambda function code
- `lib/services/ec2_ip_service.dart` - Flutter service
- `lib/screens/settings_screen.dart` - Updated settings UI

---

## Estimated Time: 1 hour total
- AWS Setup: 30 min
- Flutter Update: 10 min
- Testing: 15 min
- Documentation: 5 min

---

## Got Questions?

Refer to:
1. `AWS_LAMBDA_SETUP.md` for detailed AWS steps
2. `ARCHITECTURE_DIAGRAM.md` to understand the flow
3. `QUICK_REFERENCE.md` for quick answers

---

**Next Step**: Start with "Phase 1: AWS Lambda Setup" ☝️
