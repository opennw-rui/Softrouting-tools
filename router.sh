#!/usr/bin/env bash

_complete_router() {
    local cur prev words cword
    _init_completion || return

    # 动态获取网络接口列表
    local interfaces
    interfaces=$(ip -o link show 2>/dev/null | awk '{gsub(/:.*$/, "", $2); gsub(/@.*$/, "", $2); print $2}' | sort -u)

    # 第一级命令
    if [[ $cword -eq 1 ]]; then
        COMPREPLY=($(compgen -W "table interface packets session help -h" -- "$cur"))
        return 0
    fi

    # ==================== router table ====================
    if [[ "${words[1]}" == "table" ]]; then
        if [[ $cword -eq 2 ]]; then
            COMPREPLY=($(compgen -W "add del show -h --help" -- "$cur"))
            return 0
        fi

        case "${words[2]}" in
            add|del)
                local subcmd_start=3
                if [[ "${words[3]}" == "ipv4" || "${words[3]}" == "ipv6" ]]; then
                    subcmd_start=4
                fi

                case "$prev" in
                    file)
                        _filedir
                        return 0
                        ;;
                    dev)
                        COMPREPLY=($(compgen -W "null0 ${interfaces[*]}" -- "$cur"))
                        return 0
                        ;;
                    table)
                        COMPREPLY=($(compgen -W "main local default all" -- "$cur"))
                        return 0
                        ;;
                    vrf|nextvrf)
                        COMPREPLY=($(compgen -W "default ${interfaces[*]}" -- "$cur"))
                        return 0
                        ;;
                    type)
                        COMPREPLY=($(compgen -W "unicast local broadcast multicast" -- "$cur"))
                        return 0
                        ;;
                    via)
                        return 0
                        ;;
                esac

                if [[ $cword -eq $subcmd_start ]]; then
                    COMPREPLY=($(compgen -W "<network> file" -- "$cur"))
                    return 0
                elif [[ $cword -eq $((subcmd_start + 1)) && "${words[$subcmd_start]}" != "file" ]]; then
                    return 0
                else
                    COMPREPLY=($(compgen -W "proce dev table vrf nextvrf cost prefsrc type via" -- "$cur"))
                    return 0
                fi
                ;;

            show)
                case "$prev" in
                    -p)
                        COMPREPLY=($(compgen -W "all" -- "$cur"))
                        return 0
                        ;;
                    -i)
                        return 0
                        ;;
                    table)
                        COMPREPLY=($(compgen -W "main local default all" -- "$cur"))
                        return 0
                        ;;
                    vrf)
                        COMPREPLY=($(compgen -W "default ${interfaces[*]}" -- "$cur"))
                        return 0
                        ;;
                    pro)
                        COMPREPLY=($(compgen -W "static kernel bgp ospf rip zebra" -- "$cur"))
                        return 0
                        ;;
                esac

                COMPREPLY=($(compgen -W "ipv4 ipv6 -p -i table vrf pro neigh" -- "$cur"))
                return 0
                ;;
        esac
    fi

    # ==================== router interface ====================
    if [[ "${words[1]}" == "interface" ]]; then
        if [[ $cword -eq 2 ]]; then
            COMPREPLY=($(compgen -W "show -h --help" -- "$cur"))
            return 0
        fi

        if [[ "${words[2]}" == "show" ]]; then
            if [[ $cword -eq 3 ]]; then
                COMPREPLY=($(compgen -W "ipv4 ipv6 ${interfaces[*]} -h --help" -- "$cur"))
                return 0
            fi
        fi
        return 0
    fi

    # ==================== router packets ====================
    if [[ "${words[1]}" == "packets" ]]; then
        if [[ $cword -eq 2 ]]; then
            COMPREPLY=($(compgen -W "show -h --help" -- "$cur"))
            return 0
        fi

        if [[ "${words[2]}" == "show" ]]; then
            if [[ $cword -eq 3 ]]; then
                COMPREPLY=($(compgen -W "-i --interface ${interfaces[*]} -h --help" -- "$cur"))
                return 0
            fi

            case "$prev" in
                -i|--interface)
                    COMPREPLY=($(compgen -W "${interfaces[*]}" -- "$cur"))
                    return 0
                    ;;
            esac
        fi
        return 0
    fi

    # ==================== session ====================
    if [[ "${words[1]}" == "session" ]]; then
        if [[ $cword -eq 2 ]]; then
            COMPREPLY=($(compgen -W "show counter help -h --help" -- "$cur"))
            return 0
        fi

        if [[ "${words[2]}" == "show" ]]; then
            if [[ $cword -eq 3 ]]; then
                COMPREPLY=($(compgen -W "ipv4 ipv6" -- "$cur"))
                return 0
            fi

            # 协议补全（根据程序实际可能输出的协议优化）
            case "$prev" in
                pro)
                    COMPREPLY=($(compgen -W "tcp udp icmp icmpv6 gre esp ah l2tp pptp wireguard openvpn ipip sit ipencap sctp dccp" -- "$cur"))
                    return 0
                    ;;
                status)
                    COMPREPLY=($(compgen -W "ESTABLISHED SYN_SENT SYN_RECV FIN_WAIT TIME_WAIT CLOSE CLOSE_WAIT LAST_ACK" -- "$cur"))
                    return 0
                    ;;
                flags)
                    COMPREPLY=($(compgen -W "ASSURED UNREPLIED SNAT DNAT EXPECTED OFFLOAD" -- "$cur"))
                    return 0
                    ;;
                -p|p)
                    COMPREPLY=($(compgen -W "all" -- "$cur"))
                    return 0
                    ;;
                -i|i)
                    return 0
                    ;;
            esac

            COMPREPLY=($(compgen -W "pro status flags -p -i" -- "$cur"))
            return 0
        fi

        # counter 和 help 后面不需要补全
        if [[ "${words[2]}" == "counter" || "${words[2]}" == "help" || "${words[2]}" == "-h" || "${words[2]}" == "--help" ]]; then
            return 0
        fi
        return 0
    fi

    # help 命令
    if [[ "${words[1]}" == "help" || "${words[1]}" == "-h" || "${words[1]}" == "--help" ]]; then
        return 0
    fi
}

complete -F _complete_router router