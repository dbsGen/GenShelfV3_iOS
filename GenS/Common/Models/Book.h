//
//  Book.hpp
//  hirender_iOS
//
//  Created by mac on 2017/4/13.
//  Copyright © 2017年 gen. All rights reserved.
//

#ifndef Book_hpp
#define Book_hpp

#include <core/Ref.h>
#include "Chapter.h"
#include "../nl_define.h"

using namespace hicore;

namespace nl {
    CLASS_BEGIN_N(Book, RefObject)

        string name;
        string thumb;
        string subtitle;
        string des;
        string url;

        int     index;

        StringName  shop_id;

        static bool local_books_inited;
        static map<string, Ref<Book> > local_books;

        RefMap chapters;

    public:
        // 书本名
        METHOD _FORCE_INLINE_ const string &getName() {
            return name;
        }
        METHOD _FORCE_INLINE_ void setName(const string &name) {
            this->name = name;
        }
        PROPERTY(name, getName, setName);
        // 书本缩略图
        METHOD _FORCE_INLINE_ const string &getThumb() {
            return thumb;
        }
        METHOD _FORCE_INLINE_ void setThumb(const string &thumb) {
            this->thumb = thumb;
        }
        PROPERTY(thumb, getThumb, setThumb);
        // 副标题，按照解析到的信息来，可以是作者，或者更新日期.
        // 会显示到列表页面。
        METHOD _FORCE_INLINE_ const string &getSubtitle() {
            return subtitle;
        }
        METHOD _FORCE_INLINE_ void setSubtitle(const string &subtitle) {
            this->subtitle = subtitle;
        }
        PROPERTY(subtitle, getSubtitle, setSubtitle);
        // 详细信息，漫画简介。
        METHOD _FORCE_INLINE_ const string &getDes() {
            return des;
        }
        METHOD _FORCE_INLINE_ void setDes(const string &des) {
            this->des = des;
        }
        PROPERTY(des, getDes, setDes);
        // url地址
        METHOD _FORCE_INLINE_ const string &getUrl() {
            return url;
        }
        METHOD _FORCE_INLINE_ void setUrl(const string &url) {
            this->url = url;
        }
        PROPERTY(url, getUrl, setUrl);

        // shop id
        METHOD _FORCE_INLINE_ const StringName &getShopId() {
            return shop_id;
        }

        METHOD _FORCE_INLINE_ void setShopId(const StringName &shop_id) {
            this->shop_id = shop_id;
        }
        PROPERTY(shop_id, getShopId, setShopId);

        // 读取所有已经收藏的书本。
        METHOD static RefArray localBooks();
        static const map<string, Ref<Book> > &getLocalBooks();
        static Book *parse(const string &path);
        METHOD _FORCE_INLINE_ const RefMap &getChapters() {
            return chapters;
        }
        void convertLocal();
        bool insertLocalChapter(Chapter *chapter);
        void saveChapterConfig(Chapter *chapter);
        // 移除收藏
        METHOD void removeBook();
        METHOD void removeChapter(Chapter *chapter);
        _FORCE_INLINE_ int getIndex() {
            return index;
        }
        bool movePicture(Chapter *chapter, const string &path, int idx);
        // 或者本地位置
        METHOD string picturePath(Chapter *chapter, int idx);
        METHOD string chapterPath(Chapter *chapter);

        Book() {}

    protected:

        ON_LOADED_BEGIN(cls, RefObject)
            ADD_PROPERTY(cls, "name", ADD_METHOD(cls, Book, getName), ADD_METHOD(cls, Book, setName));
            ADD_PROPERTY(cls, "thumb", ADD_METHOD(cls, Book, getThumb), ADD_METHOD(cls, Book, setThumb));
            ADD_PROPERTY(cls, "subtitle", ADD_METHOD(cls, Book, getSubtitle), ADD_METHOD(cls, Book, setSubtitle));
            ADD_PROPERTY(cls, "des", ADD_METHOD(cls, Book, getDes), ADD_METHOD(cls, Book, setDes));
            ADD_PROPERTY(cls, "url", ADD_METHOD(cls, Book, getUrl), ADD_METHOD(cls, Book, setUrl));
            ADD_PROPERTY(cls, "shop_id", ADD_METHOD(cls, Book, getShopId), ADD_METHOD(cls, Book, setShopId));
            ADD_METHOD(cls, Book, localBooks);
            ADD_METHOD(cls, Book, getChapters);
            ADD_METHOD(cls, Book, picturePath);
            ADD_METHOD(cls, Book, removeBook);
            ADD_METHOD(cls, Book, removeChapter);
        ON_LOADED_END
    CLASS_END
}

#endif /* Book_hpp */
