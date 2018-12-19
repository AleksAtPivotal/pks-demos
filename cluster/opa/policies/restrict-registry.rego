package kubernetes.admission

import data.kubernetes.namespaces

deny[msg] {
    input.request.kind.kind = "Deployment"
    input.request.operation = "CREATE"
    registry = input.request.object.spec.template.spec.containers[_].image
    name = input.request.object.metadata.name
    namespace = input.request.object.metadata.namespace
    not reg_matches_any(registry,valid_deployment_registries)
    msg = sprintf("invalid deployment: whitelisted registry not found.,
    namespace=%q, name=%q, registry=%q",
    [namespace,name,registry])
}

valid_deployment_registries = {registry |
        whitelist = ”quay.io"
        registries = split(whitelist, ",")
        registry = registries[_]
}