module JitsiMeetingLink
  JITSI_SERVER_URL = 'https://jitsi.xdec.io/'.freeze

  def meeting_url(inbox_id, contact_email, conversation_id, contact_name)
    "#{JITSI_SERVER_URL}#{meeting_room_name(inbox_id, contact_email, conversation_id, contact_name)}"
  end

  def meeting_room_name(inbox_id, contact_email, conversation_id, contact_name)
    Digest::SHA1.hexdigest("xdec-chat#{inbox_id}-#{contact_email}-#{conversation_id}-#{contact_name}")
  end
end
