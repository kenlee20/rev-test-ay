# EKS for website

### Terraform 架構
將resource分為infra與application，
* shared (基礎設施)：包含 VPC、EKS 叢集、IAM 等共用資源，確保環境穩定與安全。
* applications (應用程式)：依據不同的服務進行切割，包含 Database、Frontend 等 Kubernetes 相關資源。

```tree
.
└── terraform
    ├── applications
    │   ├── manifests
    │   │   ├── database
    │   │   └── frontend
    │   └── values
    └── shared
        ├── envs
        └── values
```

### Environment
透過使用`terraform workspace`並將相關變數拉出在`envs/{ENV}.tfvars`
* Note： 因這次並沒有多環境需求，所以直接使用`default`


### 運行方式
使用參數`-var-file`指定變數檔案
```
# plan
terraform plan -var-file="envs/default.tfvars"
# apply
terraform apply -var-file="envs/default.tfvars"
```
