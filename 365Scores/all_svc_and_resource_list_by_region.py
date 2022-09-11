import boto3
from botocore.exceptions import ClientError
from skew import scan

# Get all aws regions and create text file for output
regions = boto3.session.Session().get_available_regions('ec2')
file = open("services_and_resources_by_region.txt", "a")

# Loop on all regions
for region in regions:

    used_services = []
    total_arns = []
    file.write(f"""### Start Region Name : {region} ###\n\n""")

    try:
        # Get all resources in region by boto3
        client = boto3.client('resourcegroupstaggingapi', region_name=region)
        all_resources_in_region = client.get_resources().get('ResourceTagMappingList')

        # Extract the used services names in region from resource arn
        for resource in all_resources_in_region:
            resource_arn = resource.get('ResourceARN')
            total_arns.append(resource_arn)
            service_name = resource_arn.split(':')
            if service_name[2] not in used_services:
                used_services.append(service_name[2])

        # Write to file the used services in region array
        file.write(f"Services used in {region} region: {used_services}\n\n\n")
        count = 0

        # Get extended details by object in region (by arn)
        for arn in total_arns:
            count += 1
            scan_res = scan(arn)  # skew module function
            for res in scan_res:
                file.write(f"Resource number : {count}\nResource ARN : \"{arn}\"\nResource details : {res.data}\n\n\n")

    except ClientError as e:
        file.write(f"""Could not connect to region with error: {e}\n\n""")

    file.write(f"""### End Region Name : {region} ###\n\n\n\n\n""")

file.close()
