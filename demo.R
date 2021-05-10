## Installing the packages
## BiocManager::install("foreach")
## BiocManager::install("bwlewis/doRedis")
## BiocManager::install("Jiefei-Wang/DockerParallel")
## BiocManager::install("Jiefei-Wang/ECSFargateProvider")
## BiocManager::install("Jiefei-Wang/RedisBaseContainer")
## BiocManager::install("Jiefei-Wang/doRedisContainer")

## The package used in the example
## install.packages(boot)

## Select a region
aws.ecx::aws_list_regions()
aws.ecx::aws_set_region("us-east-1")

## Show credentials
aws.ecx::aws_get_credentials()
aws.ecx::aws_set_credentials()

## Create parallel cluster using
## ECS fargate service and bioconductor foreach doredis container
library(DockerParallel)
clusterPreset(cloudProvider = "ECSFargateProvider", container = "rbaseDoRedis")
cluster <- makeDockerCluster(workerNumber = 0L)
cluster$startCluster()

## Set the required package and the worker number
cluster$workerContainer$setRPackages("boot")
cluster$setWorkerNumber(10)

# cluster$workerContainer$setSysPackages()

## Bootstrap 95% CI for R-Squared
library(boot)
## function to obtain R-Squared from the data
rsq <- function(formula, data, indices) {
    d <- data[indices,] # allows boot to select sample
    fit <- lm(formula, data=d)
    return(summary(fit)$r.square)
}
## bootstrapping with 10000 replications
system.time({
    stats <- foreach(x= 1:10, .combine = c)%do%{
        library(boot)
        boot(data=datasets::mtcars, statistic=rsq,
             R=10000, formula=mpg~wt+disp)$t
    }
})
hist(stats, breaks = 100)


## use foreach to parallelize the bootstrap
## It might take a while to run the workers
library(foreach)
foreach::getDoParWorkers()
system.time(
    stats <- foreach(x= 1:10, .combine = c,.verbose = TRUE)%dopar%{
        library(boot)
        boot(data=datasets::mtcars, statistic=rsq,
             R=10000, formula=mpg~wt+disp)$t
    }
)
hist(stats, breaks = 100)
