# Restrict User Access to Specific Directories in Linux

## Overview
This script allows you to **restrict a user’s access** to specific directories while **blocking access to all other directories** inside a given root directory. It uses **Linux permissions and ACLs (Access Control Lists)** to achieve this.

- ✅ Restricts user access to a root directory (`/opt/lampp/htdocs` by default)
- ✅ Allows access to only specified directories
- ✅ Prevents listing of the parent directory
- ✅ Automatically installs ACL if missing
- ✅ Ensures security by restricting access to all other directories and files

## Repository Information
- **GitHub Repository:** [restrict_user_access_to_dir](https://github.com/Lalatenduswain/restrict_user_access_to_dir)
- **Clone the Repository:**
  ```bash
  git clone https://github.com/Lalatenduswain/restrict_user_access_to_dir.git
  ```

## Prerequisites
Before running the script, ensure the following requirements are met:

### 1. **Install ACL (Access Control List)**
If ACL is not installed, run:
```bash
sudo apt update && sudo apt install acl -y
```

### 2. **Ensure the User Exists**
The script requires a valid Linux user. You can create a user if needed:
```bash
sudo adduser dummyuser
```
Replace `dummyuser` with the actual username.

### 3. **Run the Script as Root (or Use Sudo)**
To apply permission changes, the script must be executed with **sudo** privileges.

## Script Usage
### **Download and Run the Script**
```bash
chmod +x restrict_user_access.sh
sudo ./restrict_user_access.sh
```

### **Script Execution Steps**
When you run the script, it will prompt for:
1. **Username** – The user whose access you want to restrict.
2. **Base Directory** – The root directory where access needs to be managed.
3. **Allowed Directories** – A list of directories where the user should have full access.

Example:
```
Enter the username to restrict: dummyuser
Enter the base directory (default: /opt/lampp/htdocs):
Enter the directories the user should access (comma-separated): project1,project2
```

## How the Script Works
### **1️⃣ Restricts Access to Parent Directory**
- Sets `/opt/lampp/htdocs` permissions to `750` (only `daemon` can list files, the user cannot).
- Grants **traversal-only** (`--x`) permission to the user for the root directory.

### **2️⃣ Grants Access to Specific Directories**
- Gives `rwx` access (`read, write, execute`) to only the specified directories.

### **3️⃣ Restricts Access to All Other Directories**
- Ensures that any other directory inside the root path is **blocked** for the user.
- Files are set to `640` (only readable by owner and group).

## Example of Expected Behavior
| Action | Expected Behavior |
|--------|------------------|
| `ls /opt/lampp/htdocs/` | ❌ Permission denied |
| `cd /opt/lampp/htdocs/project1/` | ✅ Allowed |
| `ls /opt/lampp/htdocs/project1/` | ✅ Allowed |
| `cd /opt/lampp/htdocs/otherdir/` | ❌ Permission denied |

## Disclaimer | Running the Script
**Author:** Lalatendu Swain | [GitHub](https://github.com/Lalatenduswain) | [Website](https://blog.lalatendu.info/)

This script is provided as-is and may require modifications or updates based on your specific environment and requirements. Use it at your own risk. The authors of the script are not liable for any damages or issues caused by its usage.

## Donations
If you find this script useful and want to show your appreciation, you can donate via [Buy Me a Coffee](https://www.buymeacoffee.com/lalatendu.swain).

## Support or Contact
Encountering issues? Don't hesitate to submit an issue on our [GitHub page](https://github.com/Lalatenduswain/restrict_user_access_to_dir/issues).
