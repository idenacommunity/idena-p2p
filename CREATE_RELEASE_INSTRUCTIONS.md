# GitHub Release Creation Instructions

**Version**: v0.1.1-alpha
**Status**: ⚠️ **BLOCKED** - Insufficient Permissions

---

## 🚫 Issue Detected

The GitHub CLI (`gh`) is authenticated with account **truongfelix** which has:
- ✅ **Read access** (pull: true)
- ❌ **Write access** (push: false)
- ❌ **Admin access** (admin: false)

**Repository**: `idenacommunity/idena-p2p`
**Owner**: `idenacommunity`

To create a GitHub release, you need **push** or **admin** permissions on the repository.

---

## ✅ What Has Been Prepared

1. ✅ **Git tag created**: `v0.1.1-alpha`
2. ✅ **Tag pushed to remote**: Successfully uploaded
3. ✅ **Release notes prepared**: Comprehensive markdown file ready
4. ❌ **GitHub release created**: BLOCKED (insufficient permissions)

---

## 🔧 Solution Options

### Option 1: Create Release via GitHub Web Interface (Recommended)

**This is the easiest solution if you don't have admin access via CLI.**

1. **Go to the releases page**:
   ```
   https://github.com/idenacommunity/idena-p2p/releases/new
   ```

2. **Fill in the form**:
   - **Tag**: Select `v0.1.1-alpha` from dropdown (already exists)
   - **Release title**: `v0.1.1-alpha - Security Fixes Release 🔐`
   - **Description**: Copy content from `/tmp/release_notes_v0.1.1-alpha.md`
   - **This is a pre-release**: ✅ Check this box (it's an alpha release)

3. **Click "Publish release"**

**Release notes file location**: `/tmp/release_notes_v0.1.1-alpha.md`

---

### Option 2: Switch GitHub Account

If you have access to the `idenacommunity` GitHub account:

```bash
# Logout current account
gh auth logout

# Login with idenacommunity account
gh auth login

# Select:
# - GitHub.com
# - HTTPS or SSH
# - Login with a token or browser
# - Paste token or authenticate via browser

# Create the release
gh release create v0.1.1-alpha \
  --title "v0.1.1-alpha - Security Fixes Release 🔐" \
  --notes-file /tmp/release_notes_v0.1.1-alpha.md \
  --prerelease
```

---

### Option 3: Grant Access to Current Account

If `truongfelix` should have admin access:

1. **Go to repository settings**:
   ```
   https://github.com/idenacommunity/idena-p2p/settings/access
   ```

2. **Add truongfelix as collaborator** with **Admin** or **Write** role

3. **Accept the invitation** (truongfelix will receive email)

4. **Run the release command again**:
   ```bash
   gh release create v0.1.1-alpha \
     --title "v0.1.1-alpha - Security Fixes Release 🔐" \
     --notes-file /tmp/release_notes_v0.1.1-alpha.md \
     --prerelease
   ```

---

### Option 4: Manual Release via API

If you have a personal access token with appropriate permissions:

```bash
# Set token as environment variable
export GITHUB_TOKEN="your_token_here"

# Create release
gh release create v0.1.1-alpha \
  --title "v0.1.1-alpha - Security Fixes Release 🔐" \
  --notes-file /tmp/release_notes_v0.1.1-alpha.md \
  --prerelease \
  --repo idenacommunity/idena-p2p
```

---

## 📋 Release Notes Content

The complete release notes are saved at:
```
/tmp/release_notes_v0.1.1-alpha.md
```

### Release Notes Summary

**Title**: `v0.1.1-alpha - Security Fixes Release 🔐`

**Key Sections**:
- ⚠️ Alpha Release Warning
- 🛡️ Critical Security Fixes (3 vulnerabilities)
- 📚 New Documentation (7 files, 88KB)
- 🔧 Technical Changes
- 🧪 Testing Status
- 📦 Installation Instructions
- 🔐 Security Features
- 🤝 Community Testing Request

**Size**: ~10KB of comprehensive release notes

---

## 🎯 Recommended Approach

**For fastest results**: Use **Option 1** (Web Interface)

1. Open browser to: https://github.com/idenacommunity/idena-p2p/releases/new
2. Tag: Select `v0.1.1-alpha`
3. Title: `v0.1.1-alpha - Security Fixes Release 🔐`
4. Description: Copy from `/tmp/release_notes_v0.1.1-alpha.md`
5. Check "This is a pre-release"
6. Click "Publish release"

**Time required**: 2-3 minutes

---

## ✅ Verification After Release

Once the release is created, verify it:

```bash
# List releases
gh release list --repo idenacommunity/idena-p2p

# View the release
gh release view v0.1.1-alpha --repo idenacommunity/idena-p2p

# Check on web
# https://github.com/idenacommunity/idena-p2p/releases/tag/v0.1.1-alpha
```

---

## 📝 What to Copy for Web Release

### Release Title
```
v0.1.1-alpha - Security Fixes Release 🔐
```

### Release Notes
```bash
# View the full release notes
cat /tmp/release_notes_v0.1.1-alpha.md

# Or copy from the file location:
# /tmp/release_notes_v0.1.1-alpha.md
```

### Settings
- ✅ This is a pre-release: **YES** (check the box)
- ✅ Create a discussion for this release: **Optional**
- ✅ Set as the latest release: **NO** (it's a pre-release)

---

## 🔗 Quick Links

- **New Release Page**: https://github.com/idenacommunity/idena-p2p/releases/new
- **Releases List**: https://github.com/idenacommunity/idena-p2p/releases
- **Repository**: https://github.com/idenacommunity/idena-p2p
- **Tag on GitHub**: https://github.com/idenacommunity/idena-p2p/releases/tag/v0.1.1-alpha

---

## 📊 Current Status

| Item | Status | Notes |
|------|--------|-------|
| Git Tag | ✅ Created | `v0.1.1-alpha` |
| Tag Pushed | ✅ Done | Visible on GitHub |
| Release Notes | ✅ Prepared | 10KB comprehensive |
| GitHub Release | ⏳ Pending | Needs web interface or permissions |

---

## 🆘 Troubleshooting

### Issue: "Tag not found" on release page
**Solution**: The tag exists. Refresh the page or select from dropdown.

### Issue: "Cannot create release" error
**Solution**: You need admin/write permissions. Use web interface or request access.

### Issue: Release notes formatting issues
**Solution**: The release notes use GitHub-flavored markdown and should render correctly.

---

## 📞 Support

If you need help creating the release:
1. Use the web interface (easiest)
2. Request admin access to the repository
3. Ask another team member with permissions

---

**Prepared**: 2026-01-13
**Git Tag**: v0.1.1-alpha ✅
**Release Notes**: Ready ✅
**GitHub Release**: Awaiting creation ⏳
