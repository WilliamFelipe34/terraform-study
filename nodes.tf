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
  subnet_ids  = aws_subnet.subnets[*].id
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