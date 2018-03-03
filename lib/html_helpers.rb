# Copyright (c) 2016-2018, Claudio Bustos Navarrete
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

module HTMLHelpers
  def a_tag(href,text)
    "<a href='#{href}'>#{text}</a>"
  end
  def a_tag_badge(href,text)
    "<a href='#{href}'><span class='badge'>#{text}</span></a>"
  end
  def lf_to_br(t)
    t.nil? ? "" : t.split("\n").join("<br/>")
  end

  def url(ruta)
    if @mobile
      "/mob#{ruta}"
    else
      ruta
    end
  end

  def put_editable(b,&block)
    params=b.params
    value=params['value'].chomp
    return 505 if value==""
    id=params['pk']
    block.call(id, value)
    return 200
  end

  def class_bootstrap_contextual(cond, prefix, clase, clase_no="default")
    cond ? "#{prefix}-#{clase}" : "#{prefix}-#{clase_no}"
  end
  def bool_class(x, yes,no,nil_class)
    if x.nil?
      nil_class
    else
      x ? yes : no
    end
  end
  def decision_class_bootstrap(type, prefix)
    suffix=case type
             when nil
               "default"
             when "yes"
               "success"
             when "no"
               "danger"
             when "undecided"
               "warning"
           end
    prefix.nil? ? suffix  : "#{prefix}-#{suffix}"
  end


  def a_textarea_editable(id, prefix, data_url, v, default_value="--")
    url_s=url(data_url)

    "<a class='textarea_editable' data-pk='#{id}' data-url='#{url_s}' href='#' id='#{prefix}-#{id}' data-placeholder='#{default_value}'>#{v}</a>"
  end

  # Generates a text input for x-editable.
  # @param id Primary key of object to edit
  # @param prefix the id for the element is 'prefix'-'id'
  # @param data_url URL for edition of text
  # @param v Current value
  # @param placeholder Placeholder for field before entering data
  # @example a_editable(user.id, 'user-name', 'user/edit/name', user.name, t(:user_name))
  def a_editable(id, prefix, data_url, v,placeholder='--')
    url_s=url(data_url)
    "<a class='name_editable' data-pk='#{id}' data-url='#{url_s}' href='#' id='#{prefix}-#{id}' data-placeholder='#{placeholder}'>#{v}</a>"
  end

  # Check if we have permission to do an edit
  def permission_a_editable(have_permit, id, prefix, data_url, v,placeholder)
    if have_permit
      a_editable(id,prefix,data_url,v,placeholder)
    else
      v
    end
  end
end