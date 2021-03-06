# Example usage:
#
# gentoo_package_mask "x11-misc/xdg-utils           < 1.1.1"
#
# Or:
#
# gentoo_package_mask "1 www-client/firefox           < 45.6.0                  >= 45.6.0
# 2  www-client/firefox-bin       < 45.6.0                  >= 45.6.0
# 3  mail-client/thunderbird      < 45.6.0                  >= 45.6.0
# 4  mail-client/thunderbird-bin
#                                 < 45.6.0                  >= 45.6.0"
#
# Or:
#
#gentoo_package_mask "www-apps/phpBB               < 3.1.10                 Vulnerable!"
function gentoo_package_mask() {
  case $1 in
    */*\<*)
      ;;
    *)
      echo "gentoo_package_mask: Invalid package: $@"
      return 1001
      ;;
  esac
  case $@ in
    1\ \ * | \ 1\ \ * | \ \ 1\ \ *)
      local gentoo_package_mask_LINE
      local gentoo_package_mask_LINE_NUM
      for gentoo_package_mask_LINE_NUM in 1 2 3 4 5 6 7 8 9
      do
        gentoo_package_mask_LINE=`echo $@ | sed "s/^ \{1,\}//" | grep "^$gentoo_package_mask_LINE_NUM  "`
        case $gentoo_package_mask_LINE in
          "")
            ;;
          *)
            gentoo_package_mask_LINE=`echo $@ | sed "s/^ \{1,\}//" | head -$gentoo_package_mask_LINE_NUM | tail -1`
            case $gentoo_package_mask_LINE in
              *\<*)
                ;;
              *)
                gentoo_package_mask_LINE=`echo $@ | sed "s/^ \{1,\}//" | head -\`expr $gentoo_package_mask_LINE_NUM + 1\` | tail -2`
                ;;
            esac
            gentoo_package_mask_LINE=`echo $gentoo_package_mask_LINE | sed -e "s/^[1-9]  //" | cut -f 1 -d '>'`
            gentoo_package_mask "$gentoo_package_mask_LINE"
            ;;
        esac
      done
      return 0
      ;;
    *Vulnerable\!*) # mask out packages that are still vulnerable
      local gentoo_package_mask_PACKAGE=`echo $(echo $@ | tr "\n" ' ' | sed -e 's/Vulnerable!/*/g' | cut -f 1 -d '*' | cut -f 1 -d '<')`
      local gentoo_package_mask_VERSION=`echo $(echo $@ | tr "\n" ' ' | sed -e 's/Vulnerable!/*/g' | cut -f 1 -d '*' | cut -f 2 -d '<')`
      ;;
    *\*\<*) # mask out packages that are still vulnerable
      local gentoo_package_mask_PACKAGE=`echo $(echo $@ | tr "\n" ' ' | cut -f 1 -d '*')`
      local gentoo_package_mask_VERSION=""
      ;;
    *)
      local gentoo_package_mask_PACKAGE=`echo $(echo $@ | tr "\n" ' ' | cut -f 1 -d '<' | cut -f 1 -d '>')`
      local gentoo_package_mask_VERSION=`echo $(echo $@ | tr "\n" ' ' | cut -f 2 -d '<' | cut -f 1 -d '>')`
      ;;
  esac
  local gentoo_package_mask_PACKAGE_FILE=`echo $gentoo_package_mask_PACKAGE | sed -e 's|/|__|g'`
  local gentoo_package_mask_FILE="$HOME/projects/gentoo_package_masking/recipes/$gentoo_package_mask_PACKAGE_FILE.rb"
  local gentoo_package_mask_DIR=`dirname $gentoo_package_mask_FILE`
  cd $HOME/projects/gentoo_package_masking || return $?
  echo
  case $gentoo_package_mask_VERSION in
    "")
      echo "Masking '$gentoo_package_mask_PACKAGE' ..."
      echo "gentoo_package_mask '$gentoo_package_mask_PACKAGE'" > $gentoo_package_mask_FILE || return $?
      ;;
    *)
      echo "Masking '<$gentoo_package_mask_PACKAGE-$gentoo_package_mask_VERSION' ..."
      echo "gentoo_package_mask '<$gentoo_package_mask_PACKAGE-$gentoo_package_mask_VERSION'" > $gentoo_package_mask_FILE || return $?
      ;;
  esac
  git add $gentoo_package_mask_FILE || return $?
  local gentoo_package_mask_DIFF=`git --no-pager diff HEAD $gentoo_package_mask_FILE`
  case $gentoo_package_mask_DIFF in
    "")
      echo "No changes"
      ;;
    *)
      echo "$gentoo_package_mask_DIFF"
      echorun gentoo_package_mask_recipe_refresh || return $?
      ;;
  esac
}
