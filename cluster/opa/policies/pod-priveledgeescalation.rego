package kubernetes.admission

import data.kubernetes.namespaces

deny[msg] {
    input.request.kind.kind = "Pod"
    input.request.operation = "CREATE"
    input.request.object.spec.containers[_].securityContext.allowPrivilegeEscalation = true
    namespace = input.request.object.metadata.namespace
    not priv_allowed
    msg = sprintf("allowPrivilegeEscalation is not allowed for the namespace: %q", [namespace])
}

deny[msg] {
    input.request.kind.kind = "Deployment"
    input.request.operation = "CREATE"
    input.request.object.spec.template.spec.containers[_].securityContext.allowPrivilegeEscalation = true
    namespace = input.request.object.metadata.namespace
    not priv_allowed
    msg = sprintf("allowPrivilegeEscalation is not allowed for the namespace: %q", [namespace])
}

deny[msg] {
    input.request.kind.kind = "ReplicaSet"
    input.request.operation = "CREATE"
    input.request.object.spec.template.spec.containers[_].securityContext.allowPrivilegeEscalation = true
    namespace = input.request.object.metadata.namespace
    not priv_allowed
    msg = sprintf("allowPrivilegeEscalation is not allowed for the namespace: %q", [namespace])
}

priv_allowed{
    namespaces[input.request.namespace].metadata.annotations["opa-allowPrivilegeEscalation"] == "true"
}
