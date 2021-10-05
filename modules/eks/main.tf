resource "aws_security_group" "sg" {
  vpc_id = "${var.vpc_id}"
  tags =  {
    Name = "${var.prefix}-sg"
  }
  egress {
    from_port = 0 
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
    prefix_list_ids = []
  }
}

resource "aws_iam_role" "cluster" {
  name = "${var.prefix}-${var.cluster_name}-role"
  assume_role_policy =  jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSVPCResourceController" {
  role = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  role = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_cloudwatch_log_group" "log" {
  name = "aws/eks/${var.prefix}-${var.cluster_name}/cluster"
  retention_in_days = var.retention_days
}

resource "aws_eks_cluster" "cluster" {
  name = "${var.prefix}-${var.cluster_name}"
  role_arn = aws_iam_role.cluster.arn
  enabled_cluster_log_types = ["api", "audit"]

  vpc_config {
    subnet_ids = var.subnet_ids
    security_group_ids = [aws_security_group.sg.id]  
  }
  depends_on = [
    aws_cloudwatch_log_group.log,
    aws_iam_role_policy_attachment.cluster-AmazonEKSVPCResourceController,
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
  ]
}


resource "aws_iam_role" "node" {
  name = "${var.prefix}-${var.cluster_name}-route-node"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonoEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonoEC2ContainerRegistryReadOnly"
  role = aws_iam_role.node.name
}

resource "aws_eks_node_group" "node-1" {
  name = aws_eks_cluster.cluster.name
  node_group_name =  "node-1"
  node_role_arn = aws_iam_role.node.arn
  subnet_ids  = var.subnet_ids 
  scaling_config {
    desired_size = var.desired_size
    max_size = var.max_size
    min_size = var.min_size
  }
  instance_types = ["t3.micro"]
  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonoEC2ContainerRegistryReadOnly
  ]
}