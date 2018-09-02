# DevOps BKK 2018 Demo

## Instruction

### Step 1: VPC Networking (~ 2.30 min)
Create key pair with the same name as `name` variable on `0-main.tf` with and run:
```
terraform init
terraform plan
terraform apply
```

### Step 2: ALB and Aurora Serverless (~ 3 min)
Run:
```
terraform get
terraform plan -no-color | grep '+\s\|-\s\|~\s'
terraform apply -auto-approve
```
To SSH tunnel to the database, run:
```
ssh-add <path to the key pair pem file>
<use aurora_ssh_tunnel output from terraform apply>
```

### Step 3: ECS and Fargate (~ 2.30 min)
Uncomment step 3 section on `main.tf` and run:
```
terraform plan -no-color | grep '+\s\|-\s\|~\s'
terraform apply -auto-approve
```

