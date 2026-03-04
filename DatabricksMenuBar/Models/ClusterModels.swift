import Foundation

struct ClustersResponse: Codable {
    let clusters: [ClusterInfo]?
}

struct ClusterInfo: Codable, Identifiable {
    let clusterId: String
    let clusterName: String
    let state: String
    let clusterSource: String?
    let creatorUserName: String?
    let sparkVersion: String?
    let nodeTypeId: String?

    var id: String { clusterId }

    enum CodingKeys: String, CodingKey {
        case clusterId = "cluster_id"
        case clusterName = "cluster_name"
        case state
        case clusterSource = "cluster_source"
        case creatorUserName = "creator_user_name"
        case sparkVersion = "spark_version"
        case nodeTypeId = "node_type_id"
    }
}
