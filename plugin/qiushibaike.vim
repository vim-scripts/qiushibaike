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
"      Version: 0.0.6
"      History:
"               0.0.1 | dantezhu | 2011-04-04 00:27:13 | initialization
"               0.0.2 | dantezhu | 2011-04-04 00:27:34 | 增加是否设置代理的功
"               能
"               0.0.3 | dantezhu | 2011-04-06 10:10:39 | 优化参数命名，执行命
"               令改为QB,QBN,QBBest,QBBestN
"               0.0.4 | dantezhu | 2011-09-29 18:39:29 | 糗百改版，对应升级
"               0.0.5 | dantezhu | 2011-10-01 11:28:09 | 增加QBReset命令，去掉
"               QBN和QBHotN命令
"               0.0.6 | dantezhu | 2012-06-13 10:24:58 | 升级beautifulsoup至
"               4.0，针对糗百改版改善匹配方法
"
"=============================================================================

if exists('g:loaded_qiushibaike')
    finish
endif
let g:loaded_qiushibaike = 1

if !has('python')
    echoerr "Error: qiushibaike.vim plugin requires Vim to be compiled with +python"
    finish
endif

if !exists('g:qiushibaike_proxy')
    let g:qiushibaike_proxy=''
endif

if !exists('g:qiushibaike_timeout')
    let g:qiushibaike_timeout=5
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

function! s:QBReset()
    call s:SetQBBuffer()
    let b:qb_cur_page=0
python << EOF
import vim
vim.current.buffer[:]=None
EOF
endfunction

function! s:QiuShiBaiKe(url)
    call s:SetQBBuffer()
    let b:qb_url=a:url
    if !exists('b:qb_cur_page')
        let b:qb_cur_page=0
    endif
    let b:qb_cur_page=b:qb_cur_page+1
    let b:qb_url=b:qb_url."/page/".b:qb_cur_page
python << EOF

import vim
import time
import urllib
import urllib2
import re
from bs4 import BeautifulSoup, Tag, NavigableString

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
        opener = urllib2.build_opener(urllib2.ProxyHandler({'http':vim.eval('g:qiushibaike_proxy')}))
        urllib2.install_opener(opener)

    url=vim.eval("b:qb_url")
    timeout = float(vim.eval("g:qiushibaike_timeout"))

    headers = {
        'User-Agent' : 'Mozilla/4.0 (compatible; MSIE 5.5; Windows NT)'
    }

    req = urllib2.Request(url, headers=headers)
    rsp = urllib2.urlopen(req, timeout=timeout)
    page = rsp.read()
    soup = BeautifulSoup(page)

    allTags = soup.find('div', attrs={'class':'col1'}).find_all('div',attrs={'class' : 'content'})

    for tag in allTags:
        for art in tag.contents:
            tmpStr = recurTags(art).encode(vim.eval("&encoding"))
            tmpStr=tmpStr.replace("\r\n",'')
            tmpStr=tmpStr.replace("\r",'\n')
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

command! -nargs=0 QB        :call s:QiuShiBaiKe("http://www.qiushibaike.com/new2/late/20")
command! -nargs=0 QBHot     :call s:QiuShiBaiKe("http://www.qiushibaike.com/new2/hot/20")
command! -nargs=0 QBReset   :call s:QBReset()
