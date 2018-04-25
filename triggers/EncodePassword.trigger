trigger EncodePassword on Org__c (before insert, before update) {
	for(Org__c org:Trigger.new){
		if(org.password__c!=null){
			try{
				String decoded = EncodingUtil.base64Decode(org.password__c).toString();
			}
			catch(Exception e){
				// it was not encoded, so it needs to be encoded
				org.password__c = EncodingUtil.base64Encode(blob.valueOf(org.password__c));
			}
		}		
	}
}