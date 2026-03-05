resource "selectel_vpc_project_v2" "ai_project" {
  name = "ai-project"
}

resource "random_password" "sa_pass" {
  length = 20
}

resource "selectel_iam_serviceuser_v1" "ai_sa" {
  name     = "ai_sa"
  password = random_password.sa_pass.result
  role {
    role_name  = "member"
    scope      = "project"
    project_id = selectel_vpc_project_v2.ai_project.id
  }
}
