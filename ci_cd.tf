// Code Pipeline Module

resource "aws_codepipeline" "codepipeline" {
  name = "sta-pipeline-02"

  role_arn = aws_iam_role.codepipe.arn
  #role_arn=aws_iam_role.ecs_task_execution_role.arn
  artifact_store {
    location = "codepipeline-us-east-1-279054277859"
    #location = aws_s3_bucket.example.bucket
    type = "S3"
  }

  stage {
    name = "SOURCE"

    action {
      name             = "SOURCE"
      namespace        = "SOURCE-NS"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["SourceArtifacts"]

      configuration = {
        ConnectionArn        = "arn:aws:codestar-connections:us-east-1:220100568835:connection/dd181e06-cc20-4b1f-83a8-b42ec18a2c45"
        FullRepositoryId     = "yoloxsta/DHW"
        BranchName           = "main"
        DetectChanges        = true
        OutputArtifactFormat = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "CONTAINER-BUILD"


    # Add Docker Build for ECS Services
    action {
      name             = "CONTAINER-BUILD"
      namespace        = "BUILD-NS"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["SourceArtifacts"]
      output_artifacts = ["DockerArtifacts"]
      version          = "1"

      configuration = {
        ProjectName = "sta-codebuild-02"
      }
    }
  }
  stage {
    name = "DEPLOY"

    action {
      name            = "DeployAction"
      namespace       = "ECS-DEPLOY-NS"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "ECS"
      input_artifacts = ["DockerArtifacts"]
      version         = "1"

      configuration = {
        ClusterName       = "will-test"
        ServiceName       = "nginx-service"
        DeploymentTimeout = "15"
      }
    }
  }
}

 
