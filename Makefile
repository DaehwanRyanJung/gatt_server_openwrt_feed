#
# Copyright (C) 2025 Dae Hwan(Ryan) Jung.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=gobbledegook
PKG_VERSION:=0.0.1

PKG_SOURCE_PROTO:=git
PKG_SOURCE_URL:=https://github.com/DaehwanRyanJung/gatt_server_openwrt.git
PKG_SOURCE_VERSION:=a027a38176418880cb4ddeec734a7c782bcea45b

PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION)-$(PKG_SOURCE_VERSION).tar.gz
PKG_RELEASE=$(PKG_SOURCE_VERSION)

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

PKG_FIXUP:=autoreconf
PKG_BUILD_PARALLEL:=1

# gobbledegook D-bus configuration file
GGK_CONF_DIR:=/etc/dbus-1/system.d/
GGK_CONF_NAME:=gobbledegook.conf
GGK_CONF_FULL:=$(GGK_CONF_DIR)$(GGK_CONF_NAME)

include $(INCLUDE_DIR)/package.mk

TARGET_LDFLAGS:=$(TARGET_LDFLAGS) -ljsoncpp

define Package/gobbledegook
	SECTION:=utils
	CATEGORY:=Utilities
	TITLE:=Bluetooth LE GATT server
	DEPENDS:=+libc +librt +libstdcpp +glib2 +bluez-daemon +jsoncpp +bluez-libs +libopenssl +libuci +libubus +libubox +libblobmsg-json
endef

define Package/gobbledegook/description
	Gobbledegook is a C/C++ standalone Linux Bluetooth LE GATT server using BlueZ over D-Bus.
endef

MAKE_OPTS:= \
	ARCH="$(LINUX_KARCH)" \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	SUBDIRS="$(PKG_BUILD_DIR)"

# CXXFLAGS for local macro definition
CXXFLAGS_V_VARIABLES :=
# CXXFLAGS_V_VARIABLES += -DV_GATT_SERVER_AUTH_y # TODO:: Temporarily disabled

CONFIGURE_ARGS += CXXFLAGS="$(CXXFLAGS_V_VARIABLES)"

define Build/Prepare
	$(call Build/Prepare/Default)
	$(CP) ./files/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(MAKE) CC=$(TARGET_CC) -C $(PKG_BUILD_DIR)
endef

define Package/$(PKG_NAME)/preinst
#!/bin/sh
[ -d $${IPKG_INSTROOT}$(GGK_CONF_DIR) ] || mkdir -p $${IPKG_INSTROOT}$(GGK_CONF_DIR)
[ -f $${IPKG_INSTROOT}$(GGK_CONF_FULL) ] && mv -f $${IPKG_INSTROOT}$(GGK_CONF_FULL) $${IPKG_INSTROOT}$(GGK_CONF_FULL).old
true
endef

define Package/$(PKG_NAME)/postrm
#!/bin/sh
[ -f $${IPKG_INSTROOT}$(GGK_CONF_FULL).old ] && mv -f $${IPKG_INSTROOT}$(GGK_CONF_FULL).old $${IPKG_INSTROOT}$(GGK_CONF_FULL)
true
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/include $(1)/usr/lib
	$(CP) $(PKG_BUILD_DIR)/include/Gobbledegook.h $(1)/usr/include/

	$(CP) $(PKG_BUILD_DIR)/src/libggk.a $(1)/usr/lib/
endef

define Package/gobbledegook/conffiles
/etc/config/gattserver
endef

define Package/gobbledegook/install
	$(INSTALL_DIR) $(1)/usr/bin $(1)/etc/config
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/src/standalone $(1)/usr/bin/ggk-standalone
	$(INSTALL_DIR) $(1)$(GGK_CONF_DIR)
	$(INSTALL_DATA) $(PKG_BUILD_DIR)$(GGK_CONF_FULL) $(1)$(GGK_CONF_FULL)
	$(INSTALL_CONF) ./files/gattserver.config $(1)/etc/config/gattserver
endef


$(eval $(call BuildPackage,gobbledegook))
