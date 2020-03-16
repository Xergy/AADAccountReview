# Azure AD Account Review Repo

## Overview
If you has a large footprint in both Active Directory and Azure Active Directory.  These tools are targeted at helping to ease the burden of the review process.

### Two script are included

```AzureADUserGroupDetails.ps1```

This script exports Azure AD Users, Groups and Group Members.

**Sample Output:**
```
2019-12-12T08.11.833 Starting AzureADInfo...
2019-12-12T08.11.836 Gathering Groups...
2019-12-12T08.11.000 Gathering Group Members...
2019-12-12T08.11.961 Finding All Unique Members Group Members...
2019-12-12T08.11.994 Gathering Detailed User Info Based on Group Members...
2019-12-12T08.11.881 Exporting Data to ...
2019-12-12T08.11.887 Exporting Data to .\Results\AzureADInfo\2019-12-12T08.11.882_AzureADInfo...
2019-12-12T08.11.094 Done!
```

```ADUserGroupComputerGPODetails.ps1```

This script exports details for AD Users, Groups, Group Members, Computers, GPOs, and GPO Links.

**Sample Output:**

```
!! Collecting Active Directory data... !!
--------------------------------------------------------------
Gathering User details...
--------------------------------------------------------------
Gathering all Computer details...
--------------------------------------------------------------
Gathering Group details...
--------------------------------------------------------------
641 Groups found, time for coffee.
Processing Group Members...
Group ACME_VIC_UAT has 15 Members to process...
Group ACME_AMS_DSP_PREPROD has 4 Members to process...
Group ACME_PROV_UAT has 4 Members to process...
...

--------------------------------------------------------------
Gathering all the OU details...
--------------------------------------------------------------
Gathering GPO details...
--------------------------------------------------------------
This could take a while, hang in there. Found 19 OUs to process...
GPO Name: ACME Java Update Disable GPODN:OU=Management/Jump Servers,OU=WindowsServers,OU=myou,OU=Member Servers,OU=Prod_AzureT,OU=ACME,OU=Partners,DC=prod,DC=dev1,DC=acme,DC=com
GPO Name: ACME Hardened Customizations GPODN:OU=Management/Jump Servers,OU=WindowsServers,OU=myou,OU=Member Servers,OU=Prod_AzureT,OU=ACME,OU=Partners,DC=prod,DC=dev1,DC=acme,DC=com
GPO Name: ACME Windows Update Services GPODN:OU=Management/Jump Servers,OU=WindowsServers,OU=myou,OU=Member
...
 
Processing GPO Links...
--------------------------------------------------------------
Done!
--------------------------------------------------------------
```

### Tips and Tricks

- Don’t just copy theses file down from GitHub.  Please Git Clone them down to a local folder and open the folder with VSCode.
- When VSCode opens a folder, it puts you in the root of the repository allowing the relative path statements in the script to run without modifications.
Results are stored in the ```.\Results``` directory
- I suggest running this script from you on PC (i.e. not a jumpbox).  You will need:
  - VS Code
  - Git
  - Azure PowerShell Modules
  - Active Directory RSAT Tools
- I personally had trouble getting the RSAT tools to run on my Win10 Corp Laptop.  This link was ultimately helpful to resolve the issue.  
  - Windows 10 - 1809 - RSAT Toolset - error code of 0x800f0954
[Link](https://social.technet.microsoft.com/Forums/en-US/42bfdd6e-f191-4813-9142-5c86a2797c53/windows-10-1809-rsat-toolset-error-code-of-0x800f0954)

### Known Issues

- Cross forest AD group members might error.  