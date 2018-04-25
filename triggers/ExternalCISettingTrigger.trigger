/**
* @author Mert YALTI
* @date 15.06.2017
* @version 1.0
*/
trigger ExternalCISettingTrigger on External_CI_Setting__c (before insert, before update) {
    for (External_CI_Setting__c xcis : Trigger.new) {
        if (xcis.password__c != null) {
            try {
                //String decoded = EncodingUtil.base64Decode(xcis.password__c).toString();
                String decrypt = DeployAPI.decryptAPIKey(xcis.password__c);
            } catch (Exception e) {
                // if decoding is failed than it means that the password is not encoded so following line encodes that.
                xcis.password__c = DeployAPI.encryptAPIKey(xcis.password__c);
            }
        }
        if (xcis.API_Token__c != null) {
            try {
                String decrypt = DeployAPI.decryptAPIKey(xcis.API_Token__c);
            } catch (Exception e) {
                // if decoding is failed than it means that the API_Token is not encoded so following line encodes that.
                xcis.API_Token__c = DeployAPI.encryptAPIKey(xcis.API_Token__c);
            }
        }
    }
}