"=============================================================================
"
"     FileName: qiushibaike.vim
"         Desc: 用vim看糗事百科
"
"       Author: dantezhu
"        Email: zny2008@gmail.com
"     HomePage: http://www.vimer.cn
"
"      Created: 2011-04-04 00:27:13
"      Version: 0.0.3
"      History:
"               0.0.3 | dantezhu | 2011-04-06 10:10:39 | 优化参数命名，执行命
"               令改为QB,QBN,QBBest,QBBestN
"               0.0.2 | dantezhu | 2011-04-04 00:27:34 | 增加是否设置代理的功
"               能
"               0.0.1 | dantezhu | 2011-04-04 00:27:13 | initialization
"
"=============================================================================


if !exists('g:qiushibaike_proxy')
    let g:qiushibaike_proxy=''
endif

let s:qb_bufname = 'qiushibaike'

function! s:SetQBBuffer()
    if bufloaded(s:qb_bufname) > 0
        execute "sb ".s:qb_bufname
    else
        execute "new ".s:qb_bufname
    endif
    set wrap
    syn match       qbSplit "^\s*\zs#.*$"
    hi def link     qbSplit        Comment
    set buftype=nofile
endfunction

function! s:QiuShiBaiKe(url,page)
call s:SetQBBuffer()
let b:qb_url=a:url
let b:qb_page=a:page
if a:page == ""
    let b:qb_cur_page=1
    let b:qb_url=b:qb_url."/page/".b:qb_cur_page
else
    let b:qb_cur_page=b:qb_cur_page+1
    let b:qb_url=b:qb_url."/page/".b:qb_cur_page
endif
python << EOF

import vim
import time
import urllib
import urllib2
import re
from BeautifulSoup import BeautifulSoup,Tag,NavigableString
from BeautifulSoup import BeautifulStoneSoup

def recurTags(tag):
    if isinstance(tag,Tag):
        if tag.has_key('class') and tag['class'] == 'tags':
            return ''

        tmpStr = ''
        for t in tag.contents:
            tmpStr += '\n'
            tmpStr += recurTags(t)

        return tmpStr

    elif isinstance(tag,NavigableString):
        if tag.string is not None:
            return tag.string
        else:
            return ''
    else:
        return repr(tag)

def QBShow():
    if len(vim.eval('g:qiushibaike_proxy')) > 0:
        opener = urllib2.build_opener( urllib2.ProxyHandler({'http':vim.eval('g:qiushibaike_proxy')}) )
        urllib2.install_opener( opener )

    url=vim.eval("b:qb_url")
    user_agent = 'Mozilla/4.0 (compatible; MSIE 5.5; Windows NT)'
    values = {'name' : 'DanteZhu',
        'location' : 'China',
        'language' : 'Python' }
    headers = { 'User-Agent' : user_agent }

    data = urllib.urlencode(values)
    req = urllib2.Request(url, data, headers)
    response = urllib2.urlopen(req)
    the_page = response.read()
    soup = BeautifulSoup(the_page,convertEntities=BeautifulStoneSoup.HTML_ENTITIES)

    allTags = soup.findAll('div',attrs={'class' : re.compile(r'\s*qiushi_body\s*article\s*')})

    for tag in allTags:
        for art in tag.contents:
            tmpStr = recurTags(art).encode(vim.eval("&encoding"))
            tmpStr=tmpStr.replace("\r\n",'')
            strList=tmpStr.split("\n")
            for line in strList:
                if len(line) > 0:
                    vim.current.buffer.append(line)
        vim.current.buffer.append("\n")
        vim.current.buffer.append('#=============================================================================')
        vim.current.buffer.append("\n")


vim.current.buffer[:]=None
QBShow()
EOF
endfunction

command! -nargs=0 QB        :call s:QiuShiBaiKe("http://www.qiushibaike.com/groups/2/latest","")
command! -nargs=0 QBN       :call s:QiuShiBaiKe("http://www.qiushibaike.com/groups/2/latest","N")
command! -nargs=0 QBHot     :call s:QiuShiBaiKe("http://www.qiushibaike.com/groups/2/hottest/day","")
command! -nargs=0 QBHotN    :call s:QiuShiBaiKe("http://www.qiushibaike.com/groups/2/hottest/day","N")
