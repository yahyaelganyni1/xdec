module JitsiMeetingLink
  JITSI_SERVER_URL = ENV.fetch('JITSI_SERVER_URL')

  def meeting_url(inbox_id, contact_email, conversation_id, contact_name, username)
    payload = {
      'context' => {
        'user' => {
          'name' => username
        }
      },
      'moderatoer' => false,
      'aud' => 'jitsi',
      'iss' => 'cce719141dfe4b84fa89461a',
      'sub' => 'jitsi.xdec.io',
      'room' => meeting_room_name(inbox_id, contact_email, conversation_id, contact_name),
      'exp' => (Time.now + 2.days).to_i,
      'nbf' => (Time.now - 1.day).to_i
    }

    jwt_jitsi = JWT.encode payload, ENV.fetch('JITSI_APP_SECRET', nil), 'HS256'

    "#{JITSI_SERVER_URL}#{meeting_room_name(inbox_id, contact_email, conversation_id, contact_name)}?jwt=#{jwt_jitsi}"
  end

  def meeting_room_name(inbox_id, contact_email, conversation_id, contact_name)
    Digest::SHA1.hexdigest("xdec-chat#{inbox_id}-#{contact_email}-#{conversation_id}-#{contact_name}")
  end
end
