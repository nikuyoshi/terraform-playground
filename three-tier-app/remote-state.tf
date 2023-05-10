terraform {
  backend "remote" {
    organization = "nikuyoshi"
    workspaces {
      name = "three-tier-app"
    }
  }
}