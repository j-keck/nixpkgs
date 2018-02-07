#! @shell@

set -e

# Re-exec ourselves in a private mount namespace so that our bind
# mounts get cleaned up automatically.
if [ "$(id -u)" = 0 ]; then
    if [ -z "$NIXOS_ENTER_REEXEC" ]; then
        export NIXOS_ENTER_REEXEC=1
        exec unshare --mount --uts -- "$0" "$@"
    else
        mount --make-rprivate /
    fi
fi

mountPoint=/mnt
command=("bash" "--login")
system=/nix/var/nix/profiles/system

while [ "$#" -gt 0 ]; do
    i="$1"; shift 1
    case "$i" in
        --root)
            mountPoint="$1"; shift 1
            ;;
        --system)
            system="$1"; shift 1
            ;;
        --help)
            exec man nixos-enter
            exit 1
            ;;
        --command|-c)
            command=("bash" "-c" "$1")
            shift 1
            ;;
        --)
            command=("$@")
            break
            ;;
        *)
            echo "$0: unknown option \`$i'"
            exit 1
            ;;
    esac
done

mkdir -m 0755 -p "$mountPoint/dev"
mount --rbind /dev "$mountPoint/dev"

# Run the activation script. Set $LOCALE_ARCHIVE to supress some Perl locale warnings.
LOCALE_ARCHIVE=$system/sw/lib/locale/locale-archive chroot "$mountPoint" "$system/activate" >&2

exec chroot "$mountPoint" "${command[@]}"