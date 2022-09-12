# AWS API Mission
## Mission files

- _all_svc_and_resource_list_by_region.py_ - this is the python script you'll run.
- _requirements.txt_ - this is the requirements that need to be installed before running the script.
- _skew.yaml_ - this is the skew module configuration file.

## Script purpose

The python script _all_svc_and_resource_list_by_region.py_ artifacts a text file called _services_and_resources_by_region.txt_.

The file contains segmentation of all aws used services and resources by region.

### Step by step guide to run the python script

Before you run the script (_all_svc_and_resource_list_by_region.py_), you need to follow these steps in order to insure that the imported modules work well:

-   Set environment variable called **SKEW_CONFIG** and set for him the value **skew.yaml***.
  
    You can do that by running the command: **"export SKEW_CONFIG=skew.yaml"** for Linux or **"set SKEW_CONFIG=skew.yaml"** for Windows
    
    >**If you running the script via Pycharm or Visualstudio etc, You can skip this step**

- Inside the **skew.yaml** file, replace _<AWS_ACCOUNT_ID>_ with your aws account id, and replace _<PROFILE_NAME>_ with your profile name **as mentioned in your aws credential file** (Usually located at ~/.aws/credentials).
  
  An example for skew.yaml file:
  ```
  ---
  accounts:
        "<AWS_ACCOUNT_ID>":
          profile: <PROFILE_NAME>
  ```
  
- Install the requirements with the following command: **pip install -r requirements.txt**

- Now you can run the python script **_all_svc_and_resource_list_by_region.py_**

# Infrastructure as Code (IAC)

For IAC question, there is three Terraform files inside the directory:
- _main.tf_ for creating all the resources
- _vars.tf_ for variable definition
- _terraform.tfvars_ for set variables values
