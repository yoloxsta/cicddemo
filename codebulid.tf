resource "aws_iam_role" "codebuild" {
  name = "codebuild-cb-service-role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "codebuild.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "codebuildpolicy" {
  name = "codebuildpolicy"
  #role = aws_iam_role.codepipe.name
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:logs:us-east-1:220100568835:log-group:/aws/codebuild/cb",
                "arn:aws:logs:us-east-1:220100568835:log-group:/aws/codebuild/cb:*"
            ],
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ]
        },
        {
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::codepipeline-us-east-1-*"
            ],
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:GetObjectVersion",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "codebuild:CreateReportGroup",
                "codebuild:CreateReport",
                "codebuild:UpdateReport",
                "codebuild:BatchPutTestCases",
                "codebuild:BatchPutCodeCoverages"
            ],
            "Resource": [
                "arn:aws:codebuild:us-east-1:220100568835:report-group/cb-*"
            ]
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "codebuild_attachment" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuildpolicy.arn
}

resource "aws_iam_policy" "codebuildpolicy1" {
  name = "codebuildpolicy1"
  #role = aws_iam_role.codepipe.name
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateNetworkInterface",
                "ec2:DescribeDhcpOptions",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DeleteNetworkInterface",
                "ec2:DescribeSubnets",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeVpcs"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateNetworkInterfacePermission"
            ],
            "Resource": "arn:aws:ec2:us-east-1:220100568835:network-interface/*",
            "Condition": {
                "StringEquals": {
                    "ec2:Subnet": [
                        "arn:aws:ec2:us-east-1:220100568835:subnet/subnet-0aa65f04c21e6c8af",
                        "arn:aws:ec2:us-east-1:220100568835:subnet/subnet-0c63265b19f25ec10"
                    ],
                    "ec2:AuthorizedService": "codebuild.amazonaws.com"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "codebuild_attachment1" {
  role       = aws_iam_role.codebuild.name
  policy_arn = aws_iam_policy.codebuildpolicy1.arn
}

resource "aws_iam_role_policy_attachment" "codebuildpolicy-attachment" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess",
    "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicFullAccess",
    "arn:aws:iam::aws:policy/AmazonElasticContainerRegistryPublicPowerUser"
  ])

  role       = aws_iam_role.codebuild.name
  policy_arn = each.value
}













#################



resource "aws_codebuild_project" "yolocodebuild" {
  name          = "sta-codebuild-02"
  description   = "test_codebuild_project"
  build_timeout = "60"
  service_role  = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "/aws/codebuild/cb"
      stream_name = "cb"
    }
  }

  source {
    type            = "CODEPIPELINE"
    buildspec       = "buildspec.yml"
    git_clone_depth = 0
  }

 # vpc_config {
 #   vpc_id = "vpc-059cd86e58041a08a"

 #   subnets = [
 #     "subnet-0c63265b19f25ec10",
 #     "subnet-0aa65f04c21e6c8af",
 #   ]

 #   security_group_ids = [
 #     "sg-093af80ac79b4b113",
 #     "sg-05fef96c9c1e689f1"
 #   ]
 # }

  tags = {
    Environment = "Test"
  }
}
