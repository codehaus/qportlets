################################################################################
#  Copyright 2007-2008 Codehaus Foundation
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
################################################################################

module PortletHelper
  #before_filter :find_user_portlet, :only => [ :portlet_close ]
  def portlet_list(column = 1)
  end
  
  def portlet_up
  end
  
  def portlet_down
  end
  
  def portlet_left
  end
  
  def portlet_right
  end
  
  def portlet_close
    render :partial => '/portlet/close', :portlet => @portlet.id
  end
  
  def render_portlets(page, col)
    if logged_in?
      user = current_user
    else
      user = User.find_by_login('anonymous')
    end
    
    populate_portlets(user, page)
    
    user_portlets = UserPortlet.find(:all, 
                                :conditions => [ 'user_id = ? AND portlets.page = ? AND user_portlets.col = ?', user.id, page, col], 
                                :order => 'user_portlets.row ASC',
                                :include => [ :portlet ]
                               )
    
    result = ''                           
    for user_portlet in user_portlets
      
      result << render_portlet(user_portlet)
    end
    return result
  end
  
  def render_portlet_options( portlet )
    render :partial => '/portlet/options'
  end
  
  def render_portlet(user_portlet)
    portlet = user_portlet.portlet
    return render( :partial => "/portlet/portlet", :locals => { :user_portlet => user_portlet, :portlet => user_portlet.portlet } )
  end
  
private
  def populate_portlets(user, page)
    # This is just a rough initial implementation, the algorithm for where to place
    # new portlets should be tuned.
    # Moving this to the portlet plugin is desirable
    sql = <<EOF
INSERT INTO USER_PORTLETS
(
  USER_ID,
  PORTLET_ID,
  ROW,
  COL
) 
SELECT 
  ?,
  P.ID,
  P.ROW,
  P.COL
  FROM PORTLETS P
 WHERE P.PAGE = ?
   AND NOT EXISTS (SELECT * FROM USER_PORTLETS UP WHERE USER_ID = ? AND UP.PORTLET_ID = P.ID)
EOF
    count = User.find_by_sql( [ sql, user.id, page, user.id ] )
    logger.info{ "Added #{count} portlets to #{user.login}'s #{page} page" }
  end
  
  #def find_user_portlet
  #  @user_portlet = UserPortlet.find_by_user_id_and_portlet_id( current_user.id, params[:portlet_id])
  #end

end