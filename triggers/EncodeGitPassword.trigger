trigger EncodeGitPassword on Git_Repository__c (before insert, before update) {
	for (Git_Repository__c git : Trigger.new) {
		Boolean isOldEncrypted = true;

		if (!Trigger.isInsert) {
			try {
				DeployAPI.decryptAPIKey(Trigger.oldMap.get(git.Id).password__c );
			} catch (Exception e) {
				System.debug(e.getMessage());
				isOldEncrypted = false;
			}
		}
		Boolean isNewEncrypted = true;
		if (git.password__c != null) {
			try {
				String decrypted = DeployAPI.decryptAPIKey(git.password__c);
			} catch (Exception e) {
				// it was not encoded, so it needs to be encoded
				isNewEncrypted = false;
			}
			//if not go in nothing to do pw is already encrypted
			if ((isOldEncrypted && !isNewEncrypted) || (!isOldEncrypted && !isNewEncrypted)) {
				git.password__c = DeployAPI.encryptAPIKey(git.password__c);
			}
		}
	}
}