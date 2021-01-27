ENVIRONMENTS = gprd gprd-cny gprd-us-east1-b gprd-us-east1-c gprd-us-east1-d gstg gstg-us-east1-b gstg-us-east1-c gstg-us-east1-d pre

.PHONY: all
generate: $(ENVIRONMENTS)

gprd: ENV = gprd
gprd: ENV_PREFIX = gprd
gprd: PROJECT = gitlab-production
gprd: gather-gcloud-ips-gprd generate-external-values-gprd

gprd-us-east1-b: ENV = gprd-us-east1-b
gprd-us-east1-b: ENV_PREFIX = gprd
gprd-us-east1-b: PROJECT = gitlab-production
gprd-us-east1-b: gather-gcloud-ips-gprd-us-east1-b generate-external-values-gprd-us-east1-b

gprd-us-east1-c: ENV = gprd-us-east1-c
gprd-us-east1-c: ENV_PREFIX = gprd
gprd-us-east1-c: PROJECT = gitlab-production
gprd-us-east1-c: gather-gcloud-ips-gprd-us-east1-c generate-external-values-gprd-us-east1-c

gprd-us-east1-d: ENV = gprd-us-east1-d
gprd-us-east1-d: ENV_PREFIX = gprd
gprd-us-east1-d: PROJECT = gitlab-production
gprd-us-east1-d: gather-gcloud-ips-gprd-us-east1-d generate-external-values-gprd-us-east1-d

gprd-cny: ENV = gprd-cny
gprd-cny: ENV_PREFIX = gprd
gprd-cny: PROJECT = gitlab-production
gprd-cny: gather-gcloud-ips-gprd-cny generate-external-values-gprd-cny

gstg: ENV = gstg
gstg: ENV_PREFIX = gstg
gstg: PROJECT = gitlab-staging-1
gstg: gather-gcloud-ips-gstg generate-external-values-gstg

gstg-us-east1-b: ENV = gstg-us-east1-b
gstg-us-east1-b: ENV_PREFIX = gstg
gstg-us-east1-b: PROJECT = gitlab-staging-1
gstg-us-east1-b: gather-gcloud-ips-gstg-us-east1-b generate-external-values-gstg-us-east1-b

gstg-us-east1-c: ENV = gstg-us-east1-c
gstg-us-east1-c: ENV_PREFIX = gstg
gstg-us-east1-c: PROJECT = gitlab-staging-1
gstg-us-east1-c: gather-gcloud-ips-gstg-us-east1-c generate-external-values-gstg-us-east1-c

gstg-us-east1-d: ENV = gstg-us-east1-d
gstg-us-east1-d: ENV_PREFIX = gstg
gstg-us-east1-d: PROJECT = gitlab-staging-1
gstg-us-east1-d: gather-gcloud-ips-gstg-us-east1-d generate-external-values-gstg-us-east1-d

pre: export ENV = pre
pre: export ENV_PREFIX = pre
pre: export PROJECT = gitlab-pre
pre: gather-gcloud-ips-pre generate-external-values-pre

gather-gcloud-ips-%:
	gcloud --project ${PROJECT} compute addresses list --format json > $*-gcloud-ips.json

generate-external-values-%:
	jsonnet --string \
	-V environment="${ENV}" \
	-V chefBaseRole="`./bin/get-role-from-chef ${ENV_PREFIX}-base`" \
	-V chefBaseRoleGkms="`gsutil cat gs://gitlab-${ENV_PREFIX}-secrets/gitlab-omnibus-secrets/${ENV_PREFIX}.enc | gcloud --project ${PROJECT} kms decrypt --location global --keyring=gitlab-secrets --key ${ENV_PREFIX} --ciphertext-file=- --plaintext-file=-`" \
	-V chefBaseDbRedisServerSidekiqRole="`./bin/get-role-from-chef ${ENV_PREFIX}-base-db-redis-server-sidekiq`" \
	-V chefBaseDbRedisServerCacheRole="`./bin/get-role-from-chef ${ENV_PREFIX}-base-db-redis-server-cache`" \
	-V chefBaseBeRole="`./bin/get-role-from-chef ${ENV_PREFIX}-base-be`" \
	-V chefBaseBeSidekiqRole="`./bin/get-role-from-chef ${ENV_PREFIX}-base-be-sidekiq`" \
	-V chefBaseFeRole="`./bin/get-role-from-chef ${ENV_PREFIX}-base-fe`" \
	--ext-str-file gcloudComputeAddresses=${ENV}-gcloud-ips.json \
	--create-output-dirs --output-file releases/gitlab/values/values-from-external-sources.${ENV}.yaml \
	releases/gitlab/values/values-from-external-sources.jsonnet
	rm "${ENV}-gcloud-ips.json"

# Checks the `make generate` doesn't modify any files, or create any new files
.PHONY: ensure-generated-content-up-to-date
ensure-generated-content-up-to-date: generate
	(git diff --exit-code && \
	        [[ "$$(git ls-files -o --directory --exclude-standard | sed q | wc -l)" == "0" ]]) || \
	(echo "Please run 'make generate'" && exit 1)
