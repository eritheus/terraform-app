# CLAUDE.md

## Repo purpose

Lab de estudos pessoal. Toda infra subida aqui roda em uma conta AWS real, então **priorize sempre o menor custo possível** ao desenhar ou alterar recursos.

## Cost-saving directives

Ao propor ou modificar infra neste repo, sempre:

- **Evite NAT Gateway** quando VPC Endpoints (Interface/Gateway) resolverem o caso. Tasks Fargate em subnets privadas alcançam CloudWatch Logs / ECR / S3 via endpoints sem o custo fixo de NAT (~$32/mo por AZ).
- **Não replique recursos por AZ sem necessidade.** Para lab, 1 AZ basta na maioria dos casos. Só multi-AZ quando o exercício for explicitamente sobre HA.
- **Prefira on-demand mínimo / serverless pay-per-request.** Ex: DynamoDB em `PAY_PER_REQUEST` em vez de capacidade provisionada; Fargate com `desired_count = 1` e CPU/memória mínimos (256/512); evite ALB/NLB se a finalidade do estudo não exigir.
- **Retenção curta de logs.** CloudWatch log groups com `retention_in_days` baixo (1–7 dias).
- **Sem recursos "para o caso de".** Não criar VPC endpoints, subnets, IAM roles ou SGs além do que o exercício atual precisa. Adicione quando o próximo módulo pedir.
- **Cuidado com recursos de cobrança contínua mesmo ociosos:** NAT Gateway, ALB/NLB, EIP não associado, RDS, EKS control plane, Interface VPC Endpoints (~$7/mo cada — usar só quando necessário).
- Antes de sugerir um recurso novo, **mencione brevemente a alternativa mais barata** e por que ela não serve (ou serve).

## Project layout

- Raiz (`*.tf`) — root module que orquestra VPC, subnets, DynamoDB e instancia os módulos ECS.
- `envs/*.tfvars` — variáveis por ambiente (`dev`, `prod`).
- Módulos compartilhados ficam em repo separado: `github.com/eritheus/terraform-modules` (referenciado via `git::` source). Para inspecionar/alterar, clonar aquele repo à parte.

## Region

Tudo fixado em `us-east-2`. Ao adicionar recursos novos, manter consistência.
