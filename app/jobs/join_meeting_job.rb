# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
#
# Copyright (c) 2016 BigBlueButton Inc. and by respective authors (see below).
#
# This program is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.
#
# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

class JoinMeetingJob < ApplicationJob
  queue_as :default

def perform(user, meeting, base_url, room_id)
    join_message = I18n.t('slack.meeting_join', user: user.name, meeting: meeting) + "(#{base_url})"
    formatted = Slack::Notifier::Util::LinkFormatter.format(join_message)
    Rails.configuration.slack_notifier.ping formatted if !Rails.configuration.slack_notifier.nil?

    ActionCable.server.broadcast "#{room_id}-#{meeting}_meeting_updates_channel",
      action: 'moderator_joined',
      moderator: 'joined'
  end
end
