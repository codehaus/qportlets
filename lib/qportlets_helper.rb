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

module QportletsHelper
  
  def render_portlets(page, col)
    if logged_in?
      user = current_user
    else
      user = User.find_by_login('anonymous')
    end
    
    populate_portlets(user, page)
    
    user_portlets = UserPortlet.find(:all, 
                                :conditions => [ 'user_id = ? AND portlets.enabled = TRUE AND ' +
                                                 'user_portlets.enabled = true AND portlets.page = ? AND ' +
                                                 'user_portlets.col = ?', user.id, page, col], 
                                :order => 'user_portlets.row ASC',
                                :include => [ :portlet ]
                               )
    
    result = ''
    for user_portlet in user_portlets
      result << render_portlet(user_portlet)
    end
    return result
  end
  
  def render_portlet_options( locals )
    render( :partial => '/qportlets/options',  :locals => locals )
  end
  
  def render_portlet(user_portlet, content_only = false)
    @portlet = user_portlet.portlet
    @user_portlet = user_portlet
    run_portlet_controller_action()
    
    locals = {}
    #Core values
    locals[:locals] = locals #Lets us pass them to sub-views easily
    locals[:user_portlet] = @user_portlet
    locals[:portlet] = @portlet
    #Defaults
    locals[:portlet_title] = @portlet.title
    locals[:portlet_options] = {}

    if content_only
      return render( :partial => "/portlets/#{@portlet.page}/#{@portlet.key}", :locals => locals )
    else
      return render( :partial => "/qportlets/qportlet", :locals => locals )
    end
  end
  
  
  
protected
  # This provides a standard hook action for the portlet handler to use
  # if it needs to do a refresh - it can ask for /home/handle_portlet - and feed in the various ids
  def internal_handle_portlet
    find_portlet()
    render_portlet(@user_portlet, true)
  end
  
  def run_portlet_controller_action
    portlet_class_name = "::#{@portlet.page.capitalize}Portlet"
    portlet_class = eval(portlet_class_name)
    
    @portlet_controller = portlet_class.new
    @portlet_controller.current_user = current_user
    @portlet_controller.request = request
    @portlet_controller.response = response
    @portlet_controller.send(@portlet.key)
  end
  
  def setup_portlet_defaults
  end
  
  
public
  
  def render_portlet_configure
    return render( :partial => "/qportlets/configure" )
  end
  
  def portlet_configure_start
    session[:qportlets_configure] = true
  end
  
  def portlet_configure_stop
    session[:qportlets_configure] = false
  end
  
  def portlet_configure?
    return session[:qportlets_configure] 
  end
  
  def show_portlet_control?(key, portlet_options)
    return false unless logged_in?
    return true unless portlet_options.has_key?(key)
    return portlet_options[key]
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
    if defined?(logger)
      logger.info{ "Added #{count} portlets to #{user.login}'s #{page} page" }
    end
  end
  
protected
  def find_portlet
    #puts Portlet.find(:all).inspect
    @portlet = ::Portlet.find_by_id(params[:portlet_id])
    raise Exception.new("Unable to find portlet #{params[:portlet_id]}") unless @portlet
    @user_portlet = UserPortlet.find_by_user_id_and_portlet_id(current_user.id, @portlet.id)
    raise Exception.new("Unable to find user_portlet for #{current_user.login}") unless @user_portlet
  end

end