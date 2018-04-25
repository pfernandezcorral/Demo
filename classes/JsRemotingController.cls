global with sharing class JsRemotingController {
    /*
    The purpose of this class is to encapsulate various methods of Apex controller
    and make these available via Javascript Remoting.
    */
    @RemoteAction
    global static String createAPIKey() {
        Personal_Settings__c mySettings = Personal_Settings__c.getInstance();
        if (String.isBlank(mySettings.API_Key__c)) {
            DeployApi.createAPIKey();
        }
        return DeployAPI.getUserAPIKey();
    }
    /**
     * Gets the list of
     * @return [description]
     */
    @RemoteAction
    global static List<String> getMetadataTypes(String orgId) {
        try {
            return MetadataTypesHelper.getMetadataTypesByOrgId(orgId);
        } catch (Exception e) {
            return null;
        }

    }

    @RemoteAction
    global static void getVlocityDependencies(Id userStoryId, String jsonSelectedMetadata){
        DeployAPI.retrieveVlocityDependencies(userStoryId, jsonSelectedMetadata);
    }

    /**
     * constructor methods.
     */
    
    public JsRemotingController() {}
    public JsRemotingController(ApexPages.StandardController sc) {}
    public JsRemotingController(GitCommitChangesController sc) {}
}