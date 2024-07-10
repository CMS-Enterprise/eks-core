module "eppemysql"{
    source = "git@github.com:CMS-Enterprise/batcave-tf-mysql.git//.?ref=migration-testing"
    ##route53_record_name = "database-dev"
    instance_class      = "db.r5.large"
    #db_instance_class   = "db.r5.large"
    database_name       = "eppe"
    name                = var.cluster_name
    ca_cert_identifier  = "rds-ca-rsa4096-g1"
    vpc_id                              = data.aws_vpc.vpc.id
    create_security_group               = "true"
    subnets                             = data.aws_subnets.private.ids
    create_db_subnet_group              = "true"
    iam_database_authentication_enabled = "true"
    apply_immediately                   = "false"
    skip_final_snapshot                 = "false"

    allowed_security_groups           = data.aws_security_groups.eksworker.ids
    worker_security_group_id          = data.aws_security_groups.eksworker.id
    cluster_security_group_id         = data.aws_security_groups.ekscluster.id
    cluster_primary_security_group_id = data.aws_security_groups.ekscluster.id

    master_username = "root"

}