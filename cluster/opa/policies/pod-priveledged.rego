package kubernetes.admission

import data.kubernetes.namespaces

deny[msg] {
    input.request.kind.kind = "Pod"
    input.request.operation = "CREATE"
    input.request.object.spec.containers[_].securityContext.privileged = true
    namespace = input.request.object.metadata.namespace
    not privpod_allowed
    msg = sprintf("Priviledged Pods are not allowed for the namespace: %q", [namespace])
}

deny[msg] {
    input.request.kind.kind = "Deployment"
    input.request.operation = "CREATE"
    input.request.object.spec.template.spec.containers[_].securityContext.privileged = true
    namespace = input.request.object.metadata.namespace
    not privpod_allowed
    msg = sprintf("Priviledged Pods are not allowed for the namespace: %q", [namespace])
}

deny[msg] {
    input.request.kind.kind = "ReplicaSet"
    input.request.operation = "CREATE"
    input.request.object.spec.template.spec.containers[_].securityContext.privileged = true
    namespace = input.request.object.metadata.namespace
    not privpod_allowed
    msg = sprintf("Priviledged Pods are not allowed for the namespace: %q", [namespace])
}

privpod_allowed{
    namespaces[input.request.namespace].metadata.annotations["opa-allowPrivileged"] == "true"
}
